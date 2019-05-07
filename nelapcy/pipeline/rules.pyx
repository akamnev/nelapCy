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
