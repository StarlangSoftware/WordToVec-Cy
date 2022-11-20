cdef class WordPair:

    cdef str word1
    cdef str word2
    cdef float related_by

    cpdef float getRelatedBy(self)
    cpdef setRelatedBy(self, float relatedBy)
    cpdef str getWord1(self)
    cpdef str getWord2(self)
