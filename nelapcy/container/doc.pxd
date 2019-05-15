cdef class Doc:
    """A sequence of Token objects."""
    cdef object vocab
    cdef public list tokens
    cdef str __ws

    cdef int append(self, str text) except -1
    cdef int append_ws(self, str text) except -1