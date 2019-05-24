"""Algorithms of tokenizer based on Bottom-Up approach"""
from ..algo.string cimport Tree
from ..container.doc cimport Doc
import re

cdef class Char:

    def __cinit__(self, CharType sym = CharType.other, int num = 0):
        self.sym = sym
        self.num = num


cdef class Span:
    """
    Класс представляет признаки подстроки
    Каждая подстрока может быть:
        словарным словом,
        пробельным символом,
        специальным словом,
        пунктуацией,
        либо не быть отнесено ни к одному из них
    """

    def __cinit__(self, str text):
        self.text = text
        self.dictionary_word = Char()
        self.special_word = Char()
        self.space = Char()
        self.punct = Char()

    def __iadd__(self, Span other):
        self.text += other.text
        self.dictionary_word = sum_span(self.dictionary_word, other.dictionary_word)
        self.special_word = sum_span(self.special_word, other.special_word)
        self.space = sum_span(self.space, other.space)
        self.punct = sum_span(self.punct, other.punct)
        return self

    def __repr__(self):
        r = list()
        r.append("text: {}, ".format(self.text))
        r.append('dw: ({}, {}), '.format(self.dictionary_word.sym, self.dictionary_word.num))
        r.append('sw: ({}, {}), '.format(self.special_word.sym, self.special_word.num))
        r.append('sp: ({}, {}), '.format(self.space.sym, self.space.num))
        r.append('pc: ({}, {}), '.format(self.punct.sym, self.punct.num))
        return ''.join(r)


cdef int score(Span n1, Span n2) except -1:
    """
    Порядок записи правил определяет очередность их применения
    """
    if n1.dictionary_word.sym == n2.dictionary_word.sym == CharType.dictionary and \
            n1.dictionary_word.num == n2.dictionary_word.num:
        if n1.special_word.sym == n2.special_word.sym == CharType.special and \
            n1.special_word.num != n2.special_word.num:
                # cant - ca nt or cant
                return SCORE_MAX + 1
        return 1
    if n1.special_word.sym == n2.special_word.sym == CharType.special and \
            n1.special_word.num == n2.special_word.num:
        return 0
    if n1.space.sym == n2.space.sym == CharType.space:
        return 0
    if n1.punct.sym == n2.punct.sym == CharType.punct:
        # etc.?
        return 2
    if n1.text.isalpha() and n2.text.isalpha():
        # ситуация когда незнакомое слово разбивается на множество подстрок
        # будем считать, что слитно может быть написано не более двух слов
        if n1.dictionary_word.sym == n2.dictionary_word.sym == CharType.dictionary and \
                n1.special_word.sym == n2.special_word.sym == CharType.other:
            return 1
        if (n1.dictionary_word.sym == CharType.other and n2.dictionary_word.sym == CharType.dictionary or
                n1.dictionary_word.sym == CharType.dictionary and n2.dictionary_word.sym == CharType.other) and \
                n1.special_word.sym == n2.special_word.sym == CharType.other:
            return 3

    # Последним объединяем символы, которые не являются пробельными
    if (n1.dictionary_word.sym == n2.dictionary_word.sym == CharType.other and
            n1.special_word.sym == n2.special_word.sym == CharType.other and
            n1.space.sym == n2.space.sym == CharType.other and
            n1.punct.sym == n2.punct.sym == CharType.other):
        return 100

    return SCORE_MAX + 1


cdef class TokenizerBottomUp:
    """Сегментация текста на основе алгоритма bottom-up"""

    def __init__(self, Tree tree, pattern_special, pattern_punctuation, whitespace_character):
        self.tree = tree
        self.whitespace_character = whitespace_character
        self.pattern_special = re.compile(pattern_special, re.UNICODE | re.IGNORECASE)
        self.pattern_punctuation = re.compile(pattern_punctuation, re.UNICODE)

    cdef list bottom_up_segmentation(self, list ts):
        if len(ts) < 2:
            return ts
        cdef list ranks = [score(ts[i], ts[i+1]) for i in range(len(ts) - 1)]
        cdef int value = min(ranks)
        cdef int idx = -1
        while value < SCORE_MAX:
            idx = ranks.index(value)
            ts[idx] += ts[idx + 1]
            ts.pop(idx + 1)
            ranks.pop(idx)
            if idx - 1 >= 0:
                ranks[idx - 1] = score(ts[idx-1], ts[idx])
            if idx < len(ranks):
                ranks[idx] = score(ts[idx], ts[idx+1])
            if not ranks:
                break
            value = min(ranks)
        return ts


    cdef list code_dictionary(self, str text, list ts):
        """
        :param text: анализируемый текст
        :param ts: последовательность интервалов, представляющих текст
        :return:
        """
        cdef int idx = 0  # номер токена
        cdef int pos = 0  # начало анализа строки
        cdef int tot = len(text)
        cdef int i
        while pos < tot:
            i = self.tree.find_in_string(text, pos)
            if i > 0:
                idx += 1
                while i > 0:
                    ts[pos].dictionary_word = Char(CharType.dictionary, idx)
                    pos += 1
                    i -= 1
            else:
                pos += 1
                idx = 0
        return ts

    cdef list code_special(self, str text, list ts):
        cdef int pos = 0
        cdef int idx = 0
        cdef int tot = len(text)
        cdef i1, i2
        while pos < tot:
            s = self.pattern_special.search(text, pos=pos)
            if s is None:
                break
            i1, i2 = s.span()
            idx = 1 if i1 > pos else idx + 1
            pos = i1
            while pos < i2:
                ts[pos].special_word = Char(CharType.special, idx)
                pos += 1
        return ts

    cdef list code_space(self, str text, list ts):
        for i in range(len(text)):
            if text[i] in self.whitespace_character:
                ts[i].space = Char(CharType.space, 0)
        return ts

    cdef list code_punct(self, str text, list ts):
        cdef int pos = 0
        cdef int tot = len(text)
        cdef i1, i2
        while pos < tot:
            s = self.pattern_punctuation.search(text, pos=pos)
            if s is None:
                break
            i1, i2 = s.span()
            pos = i1
            while pos < i2:
                ts[pos].punct = Char(CharType.punct, 0)
                pos += 1
        return ts

    cpdef list process_text(self, str text):
        ts = [Span(c) for c in text]
        ts = self.code_dictionary(text, ts)
        ts = self.code_special(text, ts)
        ts = self.code_space(text, ts)
        ts = self.code_punct(text, ts)
        return ts


    cpdef run(self, text):
        ts = self.process_text(text)
        return self.bottom_up_segmentation(ts)


cdef int consists_of(str string, str characters) except -1:
    """Функция проверяет, что string состоит только из символов из characters"""
    cnt = 0
    for s in string:
        if s in characters:
            cnt += 1
    if cnt == len(string):
        return 1
    return 0


cdef class Tokenizer(TokenizerBottomUp):
    """Токенизатор, который наследуется от класса реализующего алгоритм токенизации и добавляет создание контейнеров"""
    cdef object vocab

    def __init__(self, vocab, Tree tree, pattern_special, pattern_punctuation, whitespace_character=None):
        self.vocab = vocab
        super().__init__(tree, pattern_special, pattern_punctuation, whitespace_character)

    def run(self, text):
        """Переходим от представления в виде множества символов с их признаками 
        к простому набору токенов в виде текста и заполняем объект типа Doc
        Метод возвращает объект типа Doc
        """
        splitted_text = [x.text for x in super().run(text)]
        doc = Doc(self.vocab)
        for substring in splitted_text:
            if consists_of(substring, self.whitespace_character) == 0:
                doc.append(substring)  # token
            else:
                doc.append_ws(substring)  # space token
        return doc