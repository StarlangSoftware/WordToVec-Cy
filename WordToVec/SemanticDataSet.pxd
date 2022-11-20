from Dictionary.VectorizedDictionary cimport VectorizedDictionary

from WordToVec.WordPair cimport WordPair

cdef class SemanticDataSet:

    cdef list __pairs

    cpdef SemanticDataSet calculateSimilarities(self, VectorizedDictionary dictionary)
    cpdef int size(self)
    cpdef sort(self)
    cpdef index(self, WordPair wordPair)
    cpdef float spearmanCorrelation(self, SemanticDataSet semanticDataSet)
