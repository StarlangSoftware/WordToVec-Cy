cdef class WordPair:

    def __init__(self,
                 word1: str,
                 word2: str,
                 relatedBy: float):
        """
        Constructor of the WordPair object. WordPair stores the information about two words and their similarity scores.
        :param word1: First word
        :param word2: Second word
        :param relatedBy: Similarity score between first and second word.
        """
        self.word1 = word1
        self.word2 = word2
        self.related_by = relatedBy

    def __eq__(self, other):
        return self.getWord1() == other.getWord1() and self.getWord2() == other.getWord2()

    cpdef float getRelatedBy(self):
        """
        Accessor for the similarity score.
        :return: Similarity score.
        """
        return self.related_by

    cpdef setRelatedBy(self, float relatedBy):
        """
        Mutator for the similarity score.
        :param relatedBy: New similarity score
        """
        self.related_by = relatedBy

    cpdef str getWord1(self):
        """
        Accessor for the first word.
        :return: First word.
        """
        return self.word1

    cpdef str getWord2(self):
        """
        Accessor for the second word.
        :return: Second word.
        """
        return self.word2

    def __repr__(self):
        return f"{self.word1} {self.word2}"
