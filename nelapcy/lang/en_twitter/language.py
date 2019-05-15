# coding: utf8
"""Модуль содержит класс, который описывает язык :-)"""
from ...algo.string import Tree
from ...algo.tokenizer import Tokenizer
from ...pipeline.crf import Tagger
from ...pipeline.rules import TaggerRules, NER
from ...lemmatizer import Lemmatizer
from .lemmatizer import LEMMA_RULES, LEMMA_INDEX, LEMMA_EXC, LOOKUP
from .patterns import TOKEN_MATCH, PUNC_MATCH
from ...misc.html import replace_html_entities
import json
import os
from .tag_to_pos import TAG_MAP

DIR = os.path.dirname(__file__)


class EnglishTwitter:
    lang = 'en'

    def __init__(self):
        # Токенизатор
        tree = Tree()
        words = self._read_data('words_dictionary.json')
        tree.create_tree(words)
        self.tokenizer = Tokenizer(tree, TOKEN_MATCH, PUNC_MATCH)
        # Лемматизатор
        self.lemmatizer = Lemmatizer(LEMMA_INDEX, LEMMA_EXC, LEMMA_RULES, LOOKUP)
        # PoS tagger
        with open(os.path.join(DIR, 'gazetteer', 'token_to_pos_map.json'), 'r') as fid:
            token_to_pos_map = json.loads(fid.read())
        tagger_model = os.path.join(DIR, 'tagger', 'model.crf')
        self.tagger_crf = Tagger(tagger_model, token_to_pos_map=token_to_pos_map)
        # Корректор PoS tagger
        self.tagger_rules = TaggerRules()
        # NER
        with open(os.path.join(DIR, 'ner', 'lookup.json'), 'r') as fp:
            lookup = json.load(fp)
        self.ner = NER(lookup=lookup)

    def make_doc(self, text):
        text = replace_html_entities(text)  # TODO: надо бы проверить что делает эта функция
        doc = self.tokenizer.run(text)
        # TODO: add pipeline's functions
        # PoS and Sentence
        self.tagger_crf(doc)
        # Корректировка PoS and Sentence
        self.tagger_rules(doc)
        # UNIV PoS and Lemmatizer
        for token in doc:
            token.pos = TAG_MAP[token.tag]
            # TODO: слова типа #bitcoin/NN -> bitcoin
            text, tag = token.text, token.tag
            if text[0] == '#' and tag != 'HT' or text[0] == '$' and tag != 'CT':
                text = text[1:]
            token.lemma = self.lemmatizer(text, token.pos)[0]
        # NER
        self.ner(doc)

        return doc

    def __call__(self, text, *args, **kwargs):
        return self.make_doc(text)

    @staticmethod
    def _read_data(filename):
        dir_gazetteer = os.path.join(DIR, 'gazetteer')
        with open(os.path.join(dir_gazetteer, filename), 'r') as fp:
            return json.load(fp)
