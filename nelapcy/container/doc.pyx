# coding: utf8
import numpy as np
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
        self.__vector = None

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

    def create(self, doc):
        """
        Построение объекта типа Doc из списка заданных токенов

        doc - список словарей
            поля словаря:
                before,
                text,
                after,
                tag,
                snt,
                ne
        """
        self.tokens = list()
        self.__ws = ''
        for token in doc:
            if 'before' in token:
                self.append_ws(token['before'])
            if 'text' in token:
                self.append(token['text'])
            if 'after' in token:
                self.append_ws(token['after'])
        for t1, t2 in zip(doc, self):
            if 'tag' in t1:
                t2.tag = t1['tag']
            if 'snt' in t1:
                t2.snt = t1['snt']
            if 'ne' in t1:
                t2.ne = t1['ne']
        return self

    def named_entities(self, lemmatize=False, sentence=True):
        """метод возвращает список именнованных сущностей найденных в документе.

        lemmatize -- возвращать леммы именнованных сущностей
        sentence -- именнованная сущность встречается только в предложении
        """
        ne = []
        for token in self:
            if token.ne[0] == 'B':
                ne.append([token])
            elif token.ne[0] == 'I':
                ne[-1].append(token)
        if sentence:
            ne = [x for x in ne if x[0].snt in ['B_Sentence', 'I_Sentence']]
        if lemmatize:
            ne = [{'text': [t.lemma for t in x], 'class': x[0].ne[2:]} for x in ne]
        else:
            ne = [{'text': [t.text for t in x], 'class': x[0].ne[2:]} for x in ne]
        ne = [{'text': ' '.join(x['text']), 'class': x['class']} for x in ne]
        return ne

    def vector(self):
        """возвращает векторное представление текста"""
        if self.__vector is not None:
            return self.__vector

        shape = self.vocab[next(iter(self.vocab))].shape
        self.__vector = np.zeros(shape, dtype=float)
        for t in self.tokens:
            try:
                self.__vector += self.vocab[t.text]
            except KeyError:
                pass
        l = len(self.tokens)
        if l:
            self.__vector /= l
        return self.__vector