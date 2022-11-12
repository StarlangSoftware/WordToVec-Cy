from Dictionary.Word cimport Word
from WordToVec.VocabularyWord cimport VocabularyWord


cdef class Vocabulary:

    cdef list __vocabulary
    cdef list __table
    cdef int __total_number_of_words

    cpdef int size(self)
    cpdef int getPosition(self, Word word)
    cpdef int getTotalNumberOfWords(self)
    cpdef VocabularyWord getWord(self, int index)
    cpdef __constructHuffmanTree(self)
    cpdef __createUniGramTable(self)
    cpdef int getTableValue(self, int index)
    cpdef int getTableSize(self)
