cdef class Token:
    cdef object vocab
    cdef public str text
    cdef public str before
    cdef public str after
    cdef public str lemma
    cdef public str tag
    cdef public str pos
    cdef public str snt
    cdef public str ne

    cdef str __shape
    cdef str __short_shape

    cpdef shape(self)
    cpdef short_shape(self)