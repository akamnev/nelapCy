# cython: infer_types=True
# coding: utf8

# cimport numpy as np
# np.import_array()

# import numpy

# from .. import parts_of_speech
# from .. import util
# from ..compat import is_config
# from ..errors import Errors, Warnings, user_warning, models_warning


cdef class Token:
    """
    Класс представляет собой токен - всякая атомарная подстрока текста.
    К данному классу не относятся пробельные символы.
    Токен обладает такими атрибутами как:
        text - оригинальный текст
        before - пробельные символы перед данным токеном
        after - пробельные символы после данного токена

        pos - огрубленная часть речи
        tag - точная часть речи
        lemma - лемма данного токена
        snt - строка, обозначающее положение токена в предложении

        и т.п. признаки, которые могут быть отнесены к токену.
    """

    def __cinit__(self, text, vocab):
        """Construct a `Token` object.

        vocab (Vocab): A storage container for lexical types.
        """
        self.vocab = vocab
        self.text = text
        self.before = ''
        self.after = ''
        self.__shape = ''
        self.__short_shape = ''

    def __len__(self):
        """The number of unicode characters in the token, i.e. `token.text`.
        RETURNS (int): The number of unicode characters in the token.
        """
        return len(self.text)

    def __unicode__(self):
        return self.text

    def __bytes__(self):
        return self.text.encode('utf8')

    def __str__(self):
        return self.__unicode__()

    def __repr__(self):
        return self.__str__()

    cpdef shape(self):

        if self.__shape != '':
            return  self.__shape

        s = list()
        for w in self.text:
            if w.isalpha():
                if w.isupper():
                    s.append('X')
                else:
                    s.append('x')
            elif w.isnumeric():
                s.append('d')
            else:
                s.append(w)
        self.__shape = ''.join(s)
        return self.__shape

    cpdef short_shape(self):
        if self.__short_shape != '':
            return self.__short_shape

        ws = self.shape()
        a = ws[0]
        s = [a]
        for w in ws:
            if a != w:
                s.append(w)
                a = w

        self.__short_shape = ''.join(s)
        return self.__short_shape


