# coding: utf8
"""Классификаторы на основе правил"""
import re


class TaggerRules:
    """Классификатор для корректировки результатов CRF алгоритма
    Атрибуты:
        snt_to_long - отображение короткого символа в длинный для предложений
        snt_to_short - отображение длинного символа предложения в короткий
        pos - список известных частей речи
        pos_to_short - отображение длинного символа части речи в короткий
        pos_to_long - отображение короткого символа части речи в длинный
    """
    snt_to_long = {
        'bh': 'B_HashTag',
        'bm': 'B_Mention',
        'bs': 'B_Sentence',
        'bu': 'B_URL',
        'ih': 'I_HashTag',
        'im': 'I_Mention',
        'is': 'I_Sentence',
        'iu': 'I_URL'
    }
    snt_to_short = {v: k for k, v in snt_to_long.items()}
    pos = [
        '"', '$', '(', ')', ',', '.', ':', 'ABB', 'CC', 'CD', 'CT', 'DT', 'EMJ', 'Ex', 'FW', 'HT', 'IN', 'JJ',
        'JJR', 'JJS', 'MD', 'NN', 'NNP', 'NNPS', 'NNS', 'PDT', 'POS', 'PRP', 'PRP$', 'RB', 'RBR', 'RBS', 'RP',
        'SYM', 'TO', 'UH', 'URL', 'USR', 'VB', 'VBD', 'VBG', 'VBN', 'VBP', 'VBZ', 'WDT', 'WP', 'WP$', 'WRB'
        ]

    def __init__(self, length=2):
        # Создаем кодирование для частей речи
        symbols = [s for s in self.generate_codes(length=length) if s not in self.snt_to_long]
        if len(symbols) >= len(self.pos):
            symbols = symbols[:len(self.pos)]
        else:
            raise ValueError('the length of symbols must be gretter than length of pos')
        self.pos_to_short = {k: v for k, v in zip(self.pos, symbols)}
        self.pos_to_long = {v: k for k, v in self.pos_to_short.items()}
        # Присваиваем код другому символу
        for s in self.generate_codes(length=length):
            if (s not in self.snt_to_long and
                    s not in self.pos_to_long):
                self.none = s

        self._patterns = self.patterns()  # скомпилированный шаблоны для корректировки входных данных

    def generate_codes(self, length=2):
        """Генерируем последовательность символов заданной длины"""
        letters = 'abcdefghijklmnopqrstuvwxyz'
        codes = [l for l in letters]
        while len(codes[0]) < length:
            codes = [c + l for c in codes for l in letters]
        return codes

    def doc_to_string(self, doc):
        """Отображение последовательности токенов, представляющий части речи и границы предложений в закодированную
        строку"""
        fval = []
        for token in doc:
            fval.append(self.pos_to_short[token.tag])
            fval.append(self.snt_to_short[token.snt])
        return ''.join(fval)

    def string_to_tags(self, string):
        """Отображение закодированной строки в последовательность токенов представляющих части речи и границы
        предложений"""
        fval = [string[i:i+2] for i in range(0, len(string), 2)]
        return [(self.pos_to_long[fval[i]], self.snt_to_long[fval[i + 1]]) for i in range(0, len(fval), 2)]

    def patterns(self):
        """
        Место где определены правила замены
        Правила написаны исходя из того, что все кодировки осуществляются двумя буквами
        """
        c = next(iter(self.pos_to_long))
        if len(c) != 2:
            raise ValueError('Code length must be 2')

        p_str = [
            (r'(?<=^..)i', 'b'),  # Всякое предложение начинается с B

            # (r'(?<=(is|bs))(bu|iu)(?=is)', 'is'),  # надо больше данных
            # (r'(?<=(is|bs))(bm|im)(?=is)', 'is'),  # не очень интересно
            # (r'(?<=(is|bs))(bh|ih)(?=is)', 'is'),  # очень мало таких случаев

            (r'(?<=is..)i(?!s)', 'b'),
            (r'(?<=ih..)i(?!h)', 'b'),
            (r'(?<=im..)i(?!m)', 'b'),
            (r'(?<=iu..)i(?!u)', 'b'),

            # (r'(?<!{pos_url})([bi]u)'.format(pos_url=pos_to_short['URL']), 'XX')
            # (r'(?<={p})is(?=..bm)'.format(p=pos_to_short['USR']), 'bm'),
            # (r'(?<=bm..)bm', 'im'),
            ]
        return [(re.compile(x, re.UNICODE), y) for x, y in p_str]

    def run(self, doc):
        """работа алгоритма"""
        string = self.doc_to_string(doc)
        for p, s in self._patterns:
            string = p.sub(s, string)
        tags = self.string_to_tags(string)
        for token, (t, s) in zip(doc, tags):
            token.tag = t
            token.snt = s
        return doc

    def __call__(self, doc):
        try:
            self.run(doc)
        except KeyError:
            pass
        return doc


class NER:
    """Класс находит именнованные сушности на основе словаря возможных имен и ряда правил
    Для выделения слова используем части речи и положение в предложении.

    Таг именованной сущности кодируется двумя латинскими символами.

    Код для каждого токена: [ne][pos][snt]

    Атрибуты:
        snt_to_long - отображение короткого символа в длинный для предложений
        snt_to_short - отображение длинного символа предложения в короткий
        pos - список известных частей речи
        pos_to_short - отображение длинного символа части речи в короткий
        pos_to_long - отображение короткого символа части речи в длинный
        ne_to_short - отображение короткого кода именнованной сущности в длинный
        ne_to_long - отображение длинного кода именнованной сущности в короткий
        lookup - таблиза именнованных сущностей разбитых по классам
            таблица должны быть словарем следующего вида {NAMED_ENTITY: [name1, name2, ...] }
    """
    snt_to_long = {
        'bh': 'B_HashTag',
        'bm': 'B_Mention',
        'bs': 'B_Sentence',
        'bu': 'B_URL',
        'ih': 'I_HashTag',
        'im': 'I_Mention',
        'is': 'I_Sentence',
        'iu': 'I_URL'
    }
    snt_to_short = {v: k for k, v in snt_to_long.items()}
    oth = 'O'  # символ токена не относящегося ни к одной из именнованной сущностей
    ne = ['O', 'B_CURRENCY', 'I_CURRENCY', 'B_ORGANISATION', 'I_ORGANISATION']
    # ne_to_short = {v: k for k, v in ne_to_long.items()}
    pos = [
        '"', 'PUNCT',
        '$', 'SYM',
        '(', 'PUNCT',
        ')', 'PUNCT',
        ',', 'PUNCT',
        '.', 'PUNCT',
        ':', 'PUNCT',
        'ABB', 'X',
        'CC', 'CCONJ',
        'CD', 'NUM',
        'CT', 'X',
        'HT', 'X',
        'DT', 'DET',
        'EMJ', 'X',
        'Ex', 'ADV',
        'FW', 'X',
        'IN', 'ADP',
        'JJ', 'ADJ',
        'JJR', 'ADJ',
        'JJS', 'ADJ',
        'MD', 'VERB',
        'NN', 'NOUN',
        'NNP', 'PROPN',
        'NNPS', 'PROPN',
        'NNS', 'NOUN',
        'PDT', 'ADJ',
        'POS', 'PART',
        'PRP', 'PRON',
        'PRP$', 'ADJ',
        'RB', 'ADV',
        'RBR', 'ADV',
        'RBS', 'ADV',
        'RP', 'PART',
        'SYM', 'SYM',
        'TO', 'PART',
        'UH', 'INTJ',
        'URL', 'X',
        'USR', 'X',
        'VB', 'VERB',
        'VBD', 'VERB',
        'VBG', 'VERB',
        'VBN', 'VERB',
        'VBP', 'VERB',
        'VBZ', 'VERB',
        'WDT', 'ADJ',
        'WP', 'NOUN',
        'WP$', 'ADJ',
        'WRB', 'ADV'
    ]
    pos = list(set(pos))


    def __init__(self, lookup=None, length=2):
        # Создаем кодирование для частей речи
        symbols = [s for s in self.generate_codes(length=length) if s not in self.snt_to_long]
        if len(symbols) >= len(self.pos):
            symbols = symbols[:len(self.pos)]
        else:
            raise ValueError('the length of symbols must be gretter than length of pos')
        self.pos_to_short = {k: v for k, v in zip(self.pos, symbols)}
        self.pos_to_long = {v: k for k, v in self.pos_to_short.items()}
        # Создаем кодировку для именнованных сущностей
        symbols = [s for s in self.generate_codes(length=length)
                   if s not in self.snt_to_long and s not in self.pos_to_long]
        if len(symbols) >= len(self.ne):
            symbols = symbols[:len(self.ne)]
        else:
            raise ValueError('the length of symbols must be gretter than length of pos')
        self.ne_to_short = {k: v for k, v in zip(self.ne, symbols)}
        self.ne_to_long = {v: k for k, v in self.ne_to_short.items()}
        # Присваиваем код другому символу
        for s in self.generate_codes(length=length):
            if (s not in self.snt_to_long and
                    s not in self.pos_to_long and
                    s not in self.ne_to_long):
                self.none = s
        # переводим словарь именнованных сущностей в формат {name: class}
        if lookup is not None:
            self.lookup = {vi: k for k, v in lookup.items() for vi in v}
        else:
            self.lookup = lookup

        self._patterns = self.patterns()  # скомпилированный шаблоны для корректировки входных данных

    def tagger(self, doc):
        """Выставляем поле токена согласно тому встречается ли он в списке именнованных сущностей"""
        cdef int idx = 0
        cdef int n = 0
        cdef list ngram = list()

        while idx + n < len(doc):
            word = doc.tokens[idx + n].text.lower()

            # если hashtag or cashtag, то выделяем содержательное слово
            # но только для первого слова
            if word[0] == '#' or word[0] == '$' and len(ngram) == 0:
                word = word[1:]

            ngram.append(word)

            if len(ngram) > 1:
                k = ' '.join(ngram)
            else:
                k = ngram[0]

            try:
                name = self.lookup[k]
                if len(ngram) == 1:
                    doc.tokens[idx + n].ne = 'B_' + name.upper()
                else:
                    doc.tokens[idx + n].ne = 'I_' + name.upper()
                n += 1
            except KeyError:
                doc.tokens[idx + n].ne = self.oth
                ngram.clear()
                idx += 1 if n == 0 else n
                n = 0
        return doc

    def generate_codes(self, length=2):
        """Генерируем последовательность символов заданной длины"""
        letters = 'abcdefghijklmnopqrstuvwxyz'
        codes = [l for l in letters]
        while len(codes[0]) < length:
            codes = [c + l for c in codes for l in letters]
        return codes

    def doc_to_string(self, doc):
        """Отображение последовательности токенов, представляющий части речи и границы предложений в закодированную
        строку"""
        fval = []
        for token in doc:
            fval.append(self.ne_to_short[token.ne])
            fval.append(self.pos_to_short[token.tag])
            fval.append(self.snt_to_short[token.snt])
        return ''.join(fval)

    def string_to_tags(self, string):
        """Отображение закодированной строки в последовательность токенов представляющих части речи и границы
        предложений"""
        fval = [string[i:i+2] for i in range(0, len(string), 2)]
        return [(self.ne_to_long[fval[i]], self.pos_to_long[fval[i + 1]], self.snt_to_long[fval[i + 2]])
                for i in range(0, len(fval), 3)]

    def patterns(self):
        """
        Место где определены правила замены
        Правила написаны исходя из того, что все кодировки осуществляются двумя буквами
        """
        c = next(iter(self.pos_to_long))
        if len(c) != 2:
            raise ValueError('Code length must be 2')
        # название именованной сущности может начинаться с NN, NNP, NNS, NNPS
        pos_b = '|'.join([self.pos_to_short[x] for x in ['NN', 'NNP', 'NNS', 'NNPS', 'HT']])
        ne_b = '|'.join([self.ne_to_short[x] for x in ['B_CURRENCY', 'B_ORGANISATION']])
        ne_i = '|'.join([self.ne_to_short[x] for x in ['I_CURRENCY', 'I_ORGANISATION']])
        oth = self.ne_to_short[self.oth]
        p_str = [
            (r'({ne_b})(?!({pos_b}))'.format(ne_b=ne_b, pos_b=pos_b),  oth),  # удаляем заголовок
            (r'(?<!({ne_b}|{ne_i})....)({ne_i})'.format(ne_b=ne_b, ne_i=ne_i), oth),
        ]
        return [(re.compile(x, re.UNICODE), y) for x, y in p_str]

    @staticmethod
    def _substitute(string, pattern, substitution):
        pos = 0
        while pos < len(string):
            res = pattern.search(string, pos=pos)
            if res is None:
                break
            i1, i2 = res.span()
            if i1 % 6 == 0:
                # проверяем то, что было найдено начало токена 2 * 3
                string = string[:i1] + substitution + string[i2:]
            pos = i2
        return string


    def run(self, doc):
        """работа алгоритма"""
        self.tagger(doc)  # раздаем названия согласно словарю
        string = self.doc_to_string(doc)
        for p, s in self._patterns:
            string = self._substitute(string, p, s)
        tags = self.string_to_tags(string)
        for token, (b, _, _) in zip(doc, tags):
            token.ne = b
        return doc

    def __call__(self, doc):
        return self.run(doc)
