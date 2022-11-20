from Corpus.AbstractCorpus cimport AbstractCorpus
from Dictionary.VectorizedDictionary cimport VectorizedDictionary
from Math.Matrix cimport Matrix

from WordToVec.Vocabulary cimport Vocabulary
from WordToVec.WordToVecParameter cimport WordToVecParameter

cdef class NeuralNetwork:

    cdef Matrix __word_vectors, __word_vector_update
    cdef Vocabulary __vocabulary
    cdef WordToVecParameter __parameter
    cdef AbstractCorpus __corpus
    cdef list __exp_table

    cpdef int vocabularySize(self)
    cpdef __prepareExpTable(self)
    cpdef VectorizedDictionary train(self)
    cpdef double __calculateG(self,
                              double f,
                              double alpha,
                              double label)
    cpdef __trainCbow(self)
    cpdef __trainSkipGram(self)
