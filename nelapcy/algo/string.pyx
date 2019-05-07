"""базовые алгоритмы работы со строчками: нахождение максимальной подстрочки"""

cdef class Node:
    # we specify class' attributes in pxd definition
    # cdef str _c
    # cdef char _is_end
    # cdef dict children

    def __cinit__(self, str c = ''):
        self.children = dict()
        self._is_end = 0
        self._c = c

    cdef Node append(self, str symbol):
        if symbol not in self.children:
            self.children[symbol] = Node(c=symbol)
        return self.children[symbol]

    cdef Node get(self, str item):
        return self.children[item]

    @property
    def c(self):
        return self._c

    @property
    def is_end(self):
        return self._is_end

cdef class Tree:
    # cdef Node _tree

    def __init__(self):
        self._tree = Node()

    cpdef add_word(self, str word):
        cdef Node node = self._tree
        for c in word:
            node = node.append(c)
        node._is_end = 1

    cpdef create_tree(self, words):
        self._tree = Node()
        for w in words:
            self.add_word(w)

    cpdef int find_in_tree(self, str word):
        cdef Node node = self._tree
        for c in word:
            try:
                node = node.get(c)
            except KeyError:
                return 0
        return node._is_end

    cpdef int find_in_string(self, str string, int idx, char lower=1):
        """Нахождение в данной строке string начиная с позиции idx подстроки из всех известных"""
        cdef int cnt = 0  # количество символов в слове
        cdef Node node = self._tree
        for i in range(idx, len(string)):
            c = string[i]
            try:
                if lower == 1:
                    c = c.lower()
                node = node.get(c)
                if node._is_end:
                    cnt = i - idx + 1
            except KeyError:
                break
        return cnt
