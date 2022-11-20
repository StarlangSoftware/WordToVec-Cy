cdef class WordPair:

    def __init__(self,
                 word1: str,
                 word2: str,
                 relatedBy: float):
        self.word1 = word1
        self.word2 = word2
        self.related_by = relatedBy

    def __eq__(self, other):
        return self.getWord1() == other.getWord1() and self.getWord2() == other.getWord2()

    cpdef float getRelatedBy(self):
        return self.related_by

    cpdef setRelatedBy(self, float relatedBy):
        self.related_by = relatedBy

    cpdef str getWord1(self):
        return self.word1

    cpdef str getWord2(self):
        return self.word2

    def __repr__(self):
        return f"{self.word1} {self.word2}"
