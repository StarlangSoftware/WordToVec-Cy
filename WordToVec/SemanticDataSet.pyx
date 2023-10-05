from functools import cmp_to_key

from Dictionary.VectorizedWord cimport VectorizedWord

cdef class SemanticDataSet:

    def __init__(self, file_name: str = None):
        cdef list lines, items
        cdef str line
        self.__pairs = []
        if file_name is not None:
            file = open(file_name, "r")
            lines = file.readlines()
            file.close()
            for line in lines:
                items = line.split(" ")
                self.__pairs.append(WordPair(items[0], items[1], float(items[2])))

    cpdef SemanticDataSet calculateSimilarities(self, VectorizedDictionary dictionary):
        cdef int i
        cdef SemanticDataSet result
        cdef str word1, word2
        cdef VectorizedWord vectorized_word1, vectorized_word2
        cdef float similarity
        result = SemanticDataSet()
        i = 0
        while i < len(self.__pairs):
            word1 = self.__pairs[i].getWord1()
            word2 = self.__pairs[i].getWord2()
            vectorized_word1 = dictionary.getWord(word1)
            vectorized_word2 = dictionary.getWord(word2)
            if word1 is not None and word2 is not None and \
                    isinstance(vectorized_word1, VectorizedWord) and isinstance(vectorized_word2, VectorizedWord):
                similarity = vectorized_word1.getVector().cosineSimilarity(vectorized_word2.getVector())
                result.__pairs.append(WordPair(word1, word2, similarity))
            else:
                self.__pairs.pop(i)
                i = i - 1
            i = i + 1
        return result

    cpdef int size(self):
        return len(self.__pairs)

    @staticmethod
    def wordPairComparator(wordPairA: WordPair, wordPairB: WordPair):
        if wordPairA.getRelatedBy() > wordPairB.getRelatedBy():
            return -1
        elif wordPairA.getRelatedBy() < wordPairB.getRelatedBy():
            return 1
        else:
            return 0

    cpdef sort(self):
        self.__pairs.sort(key=cmp_to_key(self.wordPairComparator))

    cpdef index(self, WordPair wordPair):
        cdef int i
        for i in range(len(self.__pairs)):
            if wordPair == self.__pairs[i]:
                return i
        return -1

    cpdef float spearmanCorrelation(self, SemanticDataSet semanticDataSet):
        cdef float total, ratio
        cdef int i, rank1, rank2, di, n
        total = 0
        self.sort()
        semanticDataSet.sort()
        for i in range(len(self.__pairs)):
            rank1 = i + 1
            if semanticDataSet.index(self.__pairs[i]) != -1:
                rank2 = semanticDataSet.index(self.__pairs[i]) + 1
            else:
                return -1
            di = rank1 - rank2
            total = total + 6 * di * di
        n = len(self.__pairs)
        ratio = total / (n * (n * n - 1))
        return 1 - ratio