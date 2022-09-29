from Corpus.Corpus cimport Corpus
from Corpus.Sentence cimport Sentence
from WordToVec.WordToVecParameter cimport WordToVecParameter


cdef class Iteration:

    cdef int __word_count, __last_word_count, __word_count_actual
    cdef int __iteration_count, __sentence_position, __sentence_index
    cdef double __starting_alpha, __alpha
    cdef Corpus __corpus
    cdef WordToVecParameter __word_to_vec_parameter

    cpdef double getAlpha(self)
    cpdef int getIterationCount(self)
    cpdef int getSentenceIndex(self)
    cpdef int getSentencePosition(self)
    cpdef alphaUpdate(self)
    cpdef Sentence sentenceUpdate(self, Sentence currentSentence)