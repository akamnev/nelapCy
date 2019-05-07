# coding: utf8
from .token import Token


cdef class Doc:
    """A sequence of Token objects.
    Содержит логику по выделению предложений с их типом
    """
    def __init__(self, vocab):
        """Create a Doc object.

        vocab (Vocab): A vocabulary object, which must match any models you
            want to use (e.g. tokenizer, parser, entity recognizer).
        """
        self.vocab = vocab
        self.tokens = list()
        self.__ws = ''

    cdef int append(self, str text) except -1:
        """добавление токена"""
        self.tokens.append(Token(text, self.vocab))
        self.tokens[-1].before = self.__ws
        self.__ws = ''
        return len(self)

    cdef int append_ws(self, str text) except -1:
        """добавление пробельного токена"""
        self.__ws = text
        if len(self.tokens) > 0:
            self.tokens[-1].after = self.__ws
        return len(self)

    def __len__(self):
        return len(self.tokens)

    def __iter__(self):
        for t in self.tokens:
            yield t