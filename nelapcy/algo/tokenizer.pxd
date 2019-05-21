"""Algorithms of tokenizer based on Bottom-Up approach"""
from ..algo.string cimport Tree

# we use an anonymous enum declaration to define constants
cdef enum:
    SCORE_MAX = 10000

# перечисление представляет все возможные типы символов
cdef enum CharType:
    dictionary = 1,
    special = 2,
    space = 3,
    punct = 4,
    other = 5

cdef class Char:
    cdef public CharType sym
    cdef public int num


cdef inline int _max(int i1, int i2):
    return i1 if i1 > i2 else i2


cdef inline Char sum_span(Char c1, Char c2):
    c = Char()
    if c1.sym == c2.sym:
        c.sym = c1.sym
    c.num = _max(c1.num, c2.num)
    return c


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
    cpdef public str text
    cdef public Char dictionary_word
    cdef public Char special_word
    cdef public Char space
    cdef public Char punct


cdef class TokenizerBottomUp:
    """Сегментация текста"""
    cdef Tree tree
    cdef str whitespace_character
    cdef object pattern_special
    cdef object pattern_punctuation

    cdef list bottom_up_segmentation(self, list ts)
    cdef list code_dictionary(self, str text, list ts)
    cdef list code_special(self, str text, list ts)
    cdef list code_space(self, str text, list ts)
    cdef list code_punct(self, str text, list ts)
    cpdef list process_text(self, str text)
    cpdef run(self, text)
