cdef class Node:
    cdef str _c
    cdef char _is_end
    cdef dict children

    cdef Node append(self, str symbol)
    cdef Node get(self, str item)


cdef class Tree:
    cdef Node _tree

    cpdef add_word(self, str word)
    cpdef create_tree(self, words)
    cpdef int find_in_tree(self, str word)
    cpdef int find_in_string(self, str string, int idx, char lower=*)