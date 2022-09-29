cdef class WordToVecParameter:

    cdef int __layer_size, __window, __negative_sampling_size, __number_of_iterations, __seed
    cdef bint __cbow, __hierarchical_soft_max
    cdef double __alpha

    cpdef int getLayerSize(self)
    cpdef bint isCbow(self)
    cpdef double getAlpha(self)
    cpdef int getWindow(self)
    cpdef bint isHierarchicalSoftMax(self)
    cpdef int getNegativeSamplingSize(self)
    cpdef int getNumberOfIterations(self)
    cpdef int getSeed(self)
    cpdef setLayerSize(self, int layerSize)
    cpdef setCbow(self, bint cbow)
    cpdef setAlpha(self, double alpha)
    cpdef setWindow(self, int window)
    cpdef setHierarchialSoftMax(self, bint hierarchicalSoftMax)
    cpdef setNegativeSamplingSize(self, int negativeSamplingSize)
    cpdef setNumberOfIterations(self, int numberOfIterations)
    cpdef setSeed(self, int seed)
