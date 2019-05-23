# coding: utf8

# import numpy
# cimport numpy as np
# import cytoolz
# import ujson
import re

import pycrfsuite
from ..misc.file_resource import FileResource
from ..lang.char_classes import CONCAT_ICONS
from ..lang.en_twitter.patterns import IP, URL1, URL2, HASHTAG, CASHTAG, MENTION, EMAIL, EMOJI

class PipeCRF:
    """
    Базовый класс на основе которого делается любой аннотатор на основе CRF.
    В данном классе реализована логика только предсказания. Логика для обучения реализована в отдельном классе.
    """
    name = None

    def __init__(self, modelfile, **cfg):
        """
        Create a new pipe instance.
        :param vocab:
        :param modelfile: str, path to model
        :param cfg:
        """
        if not isinstance(modelfile, str):
            raise ValueError("model must be a string")
        self._tagger = pycrfsuite.Tagger()
        self._tagger.open(modelfile)
        self.cfg = cfg

    def __call__(self, doc):
        """Apply the pipe to one document. The document is
        modified in-place, and returned.

        Both __call__ and pipe should delegate to the `predict()`
        and `set_annotations()` methods.
        """
        scores = self.predict(doc)
        self.set_annotation(doc, scores)
        return doc

    def predict(self, doc):
        """Apply the pipeline's model doc, without modifying them."""
        raise NotImplementedError

    def set_annotation(self, doc, scores):
        """Modify a document, using pre-computed scores."""
        raise NotImplementedError


class TrainBase:
    """Класс добавляет логику для обучения"""

    def __init__(self, modelfile, **cfg):
        """
        Create a new pipe instance.
        :param vocab:
        :param modelfile: str, path to model
        :param cfg:
        """
        if not isinstance(modelfile, str):
            raise ValueError("model must be a string")

        self.modelfile = FileResource(
            filename=modelfile,
            keep_tempfiles=cfg.get('keep_tempfiles', False),
            suffix=".crfsuite",
            prefix="model"
        )
        try:
            self._tagger = pycrfsuite.Tagger()
            self._tagger.open(modelfile)
        except FileNotFoundError:
            self._tagger = None
        self.training_log_ = None
        self.cfg = cfg


    def train(self, x, y, **kwargs):
        """Initialize the pipe for training, using data.
        If no model has been initialized yet, the model is added."""
        if self._tagger is not None:
            self._tagger.close()
            self._tagger = None
        self.modelfile.refresh()

        trainer = self._get_trainer(**kwargs)
        for xseq, yseq in zip(x, y):
            trainer.append(xseq, yseq)
        trainer.train(self.modelfile.name, holdout=-1)
        self.training_log_ = trainer.logparser
        self._tagger = pycrfsuite.Tagger()
        self._tagger.open(self.modelfile.name)
        return self

    def _get_trainer(self, **kwargs):
        trainer = pycrfsuite.Trainer(verbose=False)
        params = [
            'feature.minfreq',
            'feature.possible_states',
            'feature.possible_transitions',
            'c1',
            'c2',
            'max_iterations',
            'num_memories',
            'epsilon',
            'period',
            'delta',
            'linesearch',
            'max_linesearch',
            'calibration.eta',
            'calibration.rate',
            'calibration.samples',
            'calibration.candidates',
            'calibration.max_trials',
            'type',
            'c',
            'error_sensitive',
            'averaging',
            'variance',
            'gamma'
        ]
        params = {k: kwargs[k] for k in params if k in kwargs}
        trainer.set_params(params)
        return trainer


class Tagger(PipeCRF):
    """Part-of-Speech tagger and Sentence Boundary"""
    name = 'tagger'

    REGEXP_TAGS = (
        ('URL', '|'.join([IP, URL1, URL2])),
        ('HT', HASHTAG),
        ('CT', CASHTAG),
        ('USR', MENTION),
        ('EMAIL', EMAIL),
        ('EMJI', r'([{other}]+|{emoji})'.format(other=CONCAT_ICONS, emoji=EMOJI)),
    )

    SUFFIXES = (
        # Suffix    Meanings    Sample Words and Definitions
        'able',  # able to be: excitable, portable, preventable
        'ac',  # pertaining to: cardiac, hemophiliac, maniac
        'acity', 'ocity',  # quality of: perspicacity, sagacity, velocity
        'ade',  # act, action or process: product blockade, cavalcade, promenade,
        'age',  # action or process passage: pilgrimage, voyage
        'aholic', 'oholic',  # one with an obsession for: workaholic, shopaholic, alcoholic
        'al',  # relating to: bacterial, theatrical, natural
        'algia',  # pain: neuralgia, nostalgia,
        'an', 'ian',  # relating to, belonging to: Italian, urban, African
        'ance',  # state or quality of: brilliance, defiance, annoyance
        'ant',  # a person who: applicant, immigrant, servant
                # inclined to, tending to: brilliant, defiant, vigilant
        'ar',  # of or relating to, being: lunar, molecular, solar
               # a person who: beggar, burglar, liar
        'ard',  # a person who does an action: coward, sluggard, wizard
        'arian',  # a person who: disciplinarian, vegetarian, librarian
        'arium', 'orium',  # a place for: terrarium, aquarium, solarium
        'ary',  # of or relating to: literary, military, budgetary
        'ate',  # state or quality of (adj.): affectionate, desolate, obstinate
                # makes the word a verb (different pronunciation): activate, evaporate, medicate
        'ation',  # action or process: creation, narration, emancipation
        'ative',  # tending to (adj.): creative, preservative, talkative
        'cide',  # act of killing: homicide, suicide, genocide
        'cracy',  # rule, government, power: bureaucracy, aristocracy, theocracy
        'crat',  # someone who has power: aristocrat, bureaucrat, technocrat
        'cule',  # diminutive (making something small): molecule, ridicule,
        'cy',  # state, condition or quality: efficiency, privacy, belligerency
        'cycle',  # circle, wheel: bicycle, recycle, tricycle
        'dom',  # condition of, state, realm: boredom, freedom, wisdom
        'dox',  # belief, praise: orthodox, paradox
        'ectomy',  # surgical removal of: appendectomy, hysterectomy
        'ed',  # past tense: called, hammered, laughed
        'ee',  # receiver, performer: nominee, employee, devotee
        'eer',  # associated with / engaged in: engineer, volunteer
        'emia',  # blood condition: anemia, hypoglycemia, leukemia
        'en',  # makes the word a verb: awaken, fasten, strengthen
        'ence',  # state or condition, action: absence, dependence, negligence
        'ency',  # condition or quality: clemency, dependency, efficiency
        'ent',  # inclined to performing / causing, or one who performs / causes: competent, correspondent, absorbent
        'er',   # more: bigger, faster, happier
                # action or process: flutter, ponder, stutter
                # a person who does an action: announcer, barber, teacher
        'ern',  # state or quality of: eastern, northern, western
        'escence',  # state or process: adolescence, convalescence
        'ese',  # relating to a place: Chinese, Congolese, Vietnamese
        'esque',  # in the style of: Kafkaesque, grotesque, burlesque
        'ess',  # female: actress, heiress, lioness
        'est',  # most: funniest, hottest, silliest
        'etic',  # relating to (makes the word an adj.): athletic, energetic, poetic
        'ette',  # diminutive (makes something smaller): cigarette, diskette, kitchenette
        'ful',  # full of: helpful, thankful, cheerful
        'fy',  # make, cause (makes the word a verb): amplify, falsify, terrify
        'gam', 'gamy',  # marriage, union: monogam, polygamy
        'gon', 'gonic',  # angle: hexagon, polygonic, pentagon
        'hood',  # state, condition, or quality: childhood, neighborhood, motherhood
        'ial',  # relating to: celestial, editorial, martial
        'ian',  # relating to: Martian, utopian, pediatrician
        'iasis',  # diseased condition: elephantiasis, psoriasis
        'iatric',  # healing practice: pediatric, psychiatric,
        'ible',  # able to be: audible, plausible, legible
        'ic', 'ical',  # relating to, characterized by: analytic / al, comic / al, organic
        'ile',  # relating to, capable of: agile, docile, volatile
        'ily',  # in what manner: sloppily, steadily, zanily
        'ine',  # relating to: canine, feminine, masculine
        'ing',  # materials: bedding, frosting, roofing
                # action or process: dancing, seeing, writing
        'ion',  # action or process: celebration, completion, navigation
        'ious',  # having the qualities of, full of: ambitious, cautious, gracious
        'ish',  # relating to, characteristic: apish, brutish, childish
        'ism',  # state or quality: altruism, despotism, heroism
        'ist',  # a person, one who does an action: artist, linguist, pianist
        'ite',  # resident of, follower, product of: suburbanite, luddite, dynamite
        'itis',  # inflammation, preoccupation: appendicitis, tonsillitis, frontrunneritis
        'ity',  # state, condition, or quality: abnormality, civility, necessity
        'ive',  # inclined to; quality of; that which: attractive, expensive, repulsive
        'ization',  # act or process of making: colonization, fertilization, modernization
        'ize',  # cause, treat, become: antagonize, authorize, popularize
        'less',  # without: fearless, helpless, homeless
        'let',  # version of: booklet, droplet, inlet
        'like',  # resembling, characteristic: childlike, homelike, lifelike
        'ling',  # younger or inferior: duckling, underling
        'loger', 'logist',  # one who does: astrologer, cardiologist, chronologer
        'log',  # speech: dialog, monolog,
        'ly',  # in what manner: badly, courageously, happily
        'ment',  # action, result: movement, placement, shipment
        'ness',  # state or quality (makes a noun): kindness, shyness, weakness
        'oid',  # resembling: humanoid, tabloid, hemorrhoid
        'ology',  # study of, science of: anthropology, archaeology, biology
        'oma',  # tumor, swelling: carcinoma, osteoma, hematoma
        'onym',  # name, word: synonym, antonym, homonym
        'opia',  # eye defect: myopia, nyctalopia, hyperopia
        'opsy',  # examination: biopsy, autopsy, necropsy
        'or',  # a person who: inventor, legislator, translator
        'ory',  # relating to: armory, dormitory, laboratory
        'osis',  # process, diseased condition: diagnosis, prognosis, neurosis, psychosis
        'ostomy', 'otomy',  # surgical: colostomy, lobotomy, craniotomy
        'ous',  # full of: hazardous, humorous, wondrous
        'path',  # one who engages in: homeopath, naturopath, psychopath
        'pathy',  # feeling, diseased: sympathy, apathy, neuropathy
        'phile',  # one who loves: bibliophile, audiophile, pyrophile
        'phobia',  # abnormal fear of: acrophobia, claustrophobia, xenophobia
        'phone',  # sound: homophone, telephone, microphone
        'phyte',  # plant, to grow: zoophyte, cryptophyte, epiphyte
        'plegia',  # paralysis: paraplegia, quadriplegia, hemiplegia
        'plegic',  # one who is paralyzed: paraplegic, technoplegic, quadriplegic
        'pnea',  # air, spirit: apnea, hyperpnea, orthopnea
        'scopy', 'scope',  # visual exam: arthroscopy, gastroscopy, microscope
        'scribe', 'script',  # to write: transcript, describe, manuscript
        'sect',  # to cut: dissect, insect, bisect
        'ship',  # state or condition of, skill of: authorship, citizenship, friendship
        'sion',  # state or quality: confusion, depression, tension
        'some',  # characterized by, group of: cumbersome, quarrelsome, foursome
        'sophy', 'sophic',  # wisdom, knowledge: philosophy, theosophy, anthroposophic
        'th',  # state or quality: depth, length, strength
        'tion',  # state or quality: attention, caution, fascination
        'tome', 'tomy',  # to cut: hysterectomy, epitome, tonsillotome
        'trophy',  # nourishment, growth: atrophy, hypertrophy, dystrophy
        'tude',  # state, condition or quality: fortitude, gratitude, magnitude
        'ty',  # state, condition or quality: ability, honesty, loyalty
        'ular',  # relating to or resembling: cellular, circular, muscular
        'uous',  # state or quality of: arduous, tumultuous, virtuous
        'ure',  # action, condition: closure, erasure, failure
        'ward',  # specifies direction: backward, eastward, homeward
        'ware',  # things of the same type or material: hardware, software, kitchenware
        'wise',  # in what manner or direction: clockwise, lengthwise, otherwise
        'y',  # made up of, characterized: brainy, fruity, gooey
    )

    SUFFIXES_NOUN = (
        # suffix: examples of nouns
        'age',  # baggage, village, postage
        'al',  # arrival, burial, deferral
        'ance', 'ence',  # reliance, defence, insistence
        'dom',  # boredom, freedom, kingdom
        'ee',  # employee, payee, trainee
        'er', 'or',  # driver, writer, director
        'hood',  # brotherhood, childhood, neighbourhood
        'ism',  # capitalism, Marxism, socialism (philosophies)
        'ist',  # capitalist, Marxist, socialist(followers of philosophies)
        'ity', 'ty',  # brutality, equality, cruelty
        'ment',  # amazement, disappointment, parliament
        'ness',  # happiness, kindness, usefulness
        'ry',  # entry, ministry, robbery
        'ship',  # friendship, membership, workmanship
        'sion', 'tion', 'xion',  # expression, population, complexion
    )

    SUFFIXES_ADJECTIVE = (
        # suffix: examples of adjectives
        'able', 'ible',  # drinkable, portable, flexible
        'al',  # brutal, formal, postal
        'en',  # broken, golden, wooden
        'ese',  # Chinese, Japanese, Vietnamese
        'ful',  # forgetful, helpful, useful
        'i',  # Iraqi, Pakistani, Yemeni
        'ic',  # classic, Islamic, poetic
        'ish',  # British, childish, Spanish
        'ive',  # active, passive, productive
        'ian',  # Canadian, Malaysian, Peruvian
        'less',  # homeless, hopeless, useless
        'ly',  # daily, monthly, yearly
        'ous',  # cautious, famous, nervous
        'y',  # cloudy, rainy, windy
    )

    SUFFIXES_VERB = (
        # suffix: examples of verbs
        'ate',  # complicate, dominate, irritate
        'en',  # harden, soften, shorten
        'ify',  # beautify, clarify, identify
        'ise', 'ize',  # economise, realise, industrialize
    )

    SUFFIXES_ADVERB = (
        # suffix: examples of adverbs
        'ly',  # calmly, easily, quickly
        'ward',  # downwards, homeward(s), upwards
        'wards',  # downwards, homeward(s), upwards
        'wise',  # anti - clockwise, clockwise, edgewise
    )

    PREFIXES = (
        # prefix  meaning  examples
        'anti-',  # against / opposed to: anti-government, anti-racist, anti-war
        'auto',  # self: autobiography, automobile
        'de',  # reverse or change: de-classify, decontaminate, demotivate
        'dis',  # reverse or remove: disagree, displeasure, disqualify
        'down',  # reduce or lower: downgrade, downhearted
        'extra',  # beyond: extraordinary, extraterrestrial
        'hyper',  # extreme: hyperactive, hypertension
        'il', 'im', 'in', 'ir',  # not: illegal, impossible, insecure, irregular
        'inter',  # between: interactive, international
        'mega',  # very big, important: megabyte, mega-deal, megaton
        'mid',  # middle: midday, midnight, mid-October
        'mis',  # incorrectly, badly: misaligned, mislead, misspelt
        'non',  # not: non-payment, non-smoking
        'over', # too much: overcook, overcharge, overrate
        'out',  # go beyond: outdo, out-perform, outrun
        'post',  # after: post-election, post-war
        'pre',  # before: prehistoric, pre-war
        'pro',  # in favour of: pro-communist, pro-democracy
        're',  # again: reconsider, redo, rewrite
        'semi',  # half: semicircle, semi-retired
        'sub',  # under, below: submarine, sub-Saharan
        'super',  # above, beyond: super-hero, supermodel
        'tele',  # at a distance: television, telepathic
        'trans',  # across: transatlantic, transfer
        'ultra',  # extremely, ultra-compact, ultrasound
        'un',  # remove, reverse, not: undo, unpack, unhappy
        'under',  # less than, beneath: undercook, underestimate
        'up',  # make or move higher: upgrade, uphill
    )

    _token_regexp_tag = []
    for tag, exp in REGEXP_TAGS:
        _token_regexp_tag.append((tag, re.compile(exp, re.IGNORECASE).fullmatch))


    def __init__(self, modelfile, **cfg):
        super().__init__(modelfile, **cfg)
        self.token_to_pos_map = cfg['token_to_pos_map']

    def predict(self, doc):
        if self._tagger is None:
            raise ValueError('Model did not learned')
        tags = self._tagger.tag(self.features(doc))
        return tags

    def set_annotation(self, doc, tags):
        for token, tag in zip(doc, tags):
            tag = tag.split('&')
            token.tag = tag[0]
            token.snt = tag[1]

    def word_features(self, token):
        ws = token.shape()
        sws = token.short_shape()
        word = token.text
        features = [
            'isdigit=%s' % word.isdigit(),
            'shape=' + ws,
            'short_shape=' + sws,
            'before=' + token.before,
            'after=' + token.after
        ]

        for tag, func in self._token_regexp_tag:
            if func(word):
                features.append('tag=' + tag)

        for suffix in self.SUFFIXES:
            if len(word) > len(suffix) and \
                    word[-len(suffix):] == suffix:
                features.append('word.suffix=' + suffix)

        for name, suffix_pos in [
            ('SUFFIXES_NOUN', self.SUFFIXES_NOUN),
            ('SUFFIXES_VERB', self.SUFFIXES_VERB),
            ('SUFFIXES_ADJECTIVE', self.SUFFIXES_ADJECTIVE),
            ('SUFFIXES_ADVERB', self.SUFFIXES_ADVERB)
        ]:
            for suffix in suffix_pos:
                if len(word) > len(suffix) and \
                        word[-len(suffix):] == suffix:
                    features.append('suffix=' + name)

        for prefix in self.PREFIXES:
            if len(word) > len(prefix) and \
                    word[:len(prefix)] == prefix:
                features.append('prefix=' + prefix)

        if word.lower() in ['be', 'am', 'are', 'is', 'was', 'were', 'will',
                            'do', 'does', 'did', 'done',
                            'have', 'has', 'had',
                            'go', 'goes', 'went', 'gone']:
            features.append('special_verb=' + word.lower())

        try:
            w = word.lower()
            if w[0] == '#':
                w = w[1:]
            for tag in self.token_to_pos_map[w]:
                features.append('tag=' + tag)
        except KeyError:
            pass

        return features

    @staticmethod
    def words_features(features):
        new_features = [[] for _ in range(len(features))]
        for i in range(len(features) - 1):
            new_features[i].extend(['+1.' + x for x in features[i+1]])
        for i in range(1, len(features)):
            new_features[i].extend(['-1.' + x for x in features[i-1]])
        for i in range(len(features)):
            features[i].extend(new_features[i])
        return features

    def features(self, doc):
        features_ = [self.word_features(token) for token in doc]
        # features = self.words_features(features)  # не прибавляет точности
        return features_


class TaggerTrain(Tagger, TrainBase):
    """Класс для обучени PoS"""

    def __init__(self, modelfile, **cfg):
        TrainBase.__init__(self, modelfile, **cfg)
        self.token_to_pos_map = cfg['token_to_pos_map']

    def train(self, x, y, pipeline=None, **kwargs):
        features = [self.features(xi) for xi in x]
        return super().train(features, y, **kwargs)


__all__ = ["Tagger", "TaggerTrain"]
