from Corpus.Corpus cimport Corpus
from Corpus.Sentence cimport Sentence
from Dictionary.VectorizedDictionary cimport VectorizedDictionary
from Dictionary.VectorizedWord cimport VectorizedWord
from Math.Matrix cimport Matrix
from Math.Vector cimport Vector
from random import randrange

from WordToVec.Iteration cimport Iteration
from WordToVec.Vocabulary cimport Vocabulary
from WordToVec.VocabularyWord cimport VocabularyWord
from WordToVec.WordToVecParameter cimport WordToVecParameter

import math


cdef class NeuralNetwork:

    cdef Matrix __wordVectors, __wordVectorUpdate
    cdef Vocabulary __vocabulary
    cdef WordToVecParameter __parameter
    cdef Corpus __corpus
    cdef list __expTable

    EXP_TABLE_SIZE = 1000
    MAX_EXP = 6

    def __init__(self, corpus: Corpus, parameter: WordToVecParameter):
        """
        Constructor for the NeuralNetwork class. Gets corpus and network parameters as input and sets the
        corresponding parameters first. After that, initializes the network with random weights between -0.5 and 0.5.
        Constructs vector update matrix and prepares the exp table.

        PARAMETERS
        ----------
        corpus : Corpus
            Corpus used to train word vectors using Word2Vec algorithm.
        parameter : WordToVecParameter
            Parameters of the Word2Vec algorithm.
        """
        self.__vocabulary = Vocabulary(corpus)
        self.__parameter = parameter
        self.__corpus = corpus
        self.__wordVectors = Matrix(self.__vocabulary.size(), self.__parameter.getLayerSize(), -0.5, 0.5)
        self.__wordVectorUpdate = Matrix(self.__vocabulary.size(), self.__parameter.getLayerSize())
        self.__prepareExpTable()

    cpdef __prepareExpTable(self):
        """
        Constructs the fast exponentiation table. Instead of taking exponent at each time, the algorithm will lookup
        the table.
        """
        cdef int i
        self.__expTable = [0.0] * (NeuralNetwork.EXP_TABLE_SIZE + 1)
        for i in range(NeuralNetwork.EXP_TABLE_SIZE):
            self.__expTable[i] = math.exp((i / (NeuralNetwork.EXP_TABLE_SIZE + 0.0) * 2 - 1) * NeuralNetwork.MAX_EXP)
            self.__expTable[i] = self.__expTable[i] / (self.__expTable[i] + 1)

    cpdef VectorizedDictionary train(self):
        """
        Main method for training the Word2Vec algorithm. Depending on the training parameter, CBox or SkipGram algorithm
        is applied.

        RETURNS
        -------
        VectorizedDictionary
            Dictionary of word vectors.
        """
        cdef VectorizedDictionary result
        cdef int i
        result = VectorizedDictionary()
        if self.__parameter.isCbow():
            self.__trainCbow()
        else:
            self.__trainSkipGram()
        for i in range(self.__vocabulary.size()):
            result.addWord(VectorizedWord(self.__vocabulary.getWord(i).getName(), self.__wordVectors.getRowVector(i)))
        return result

    cpdef double __calculateG(self, double f, double alpha, double label):
        """
        Calculates G value in the Word2Vec algorithm.

        PARAMETERS
        ----------
        f : float
            F value.
        alpha : float
            Learning rate alpha.
        label : float
            Label of the instance.

        RETURNS
        -------
        float
            Calculated G value.
        """
        if f > NeuralNetwork.MAX_EXP:
            return (label - 1) * alpha
        elif f < -NeuralNetwork.MAX_EXP:
            return label * alpha
        else:
            return (label - self.__expTable[int((f + NeuralNetwork.MAX_EXP) *
                                                (NeuralNetwork.EXP_TABLE_SIZE // NeuralNetwork.MAX_EXP // 2))]) * alpha

    cpdef __trainCbow(self):
        """
        Main method for training the CBow version of Word2Vec algorithm.
        """
        cdef Iteration iteration
        cdef Sentence currentSentence
        cdef Vector outputs, outputUpdate
        cdef int wordIndex, b, cw, a, c, lastWordIndex, d, l2, target, label
        cdef VocabularyWord currentWord
        cdef double f, g
        iteration = Iteration(self.__corpus, self.__parameter)
        currentSentence = self.__corpus.getSentence(iteration.getSentenceIndex())
        outputs = Vector()
        outputs.initAllSame(self.__parameter.getLayerSize(), 0.0)
        outputUpdate = Vector()
        outputUpdate.initAllSame(self.__parameter.getLayerSize(), 0)
        self.__corpus.shuffleSentences(1)
        while iteration.getIterationCount() < self.__parameter.getNumberOfIterations():
            iteration.alphaUpdate()
            wordIndex = self.__vocabulary.getPosition(currentSentence.getWord(iteration.getSentencePosition()))
            currentWord = self.__vocabulary.getWord(wordIndex)
            outputs.clear()
            outputUpdate.clear()
            b = randrange(self.__parameter.getWindow())
            cw = 0
            for a in range(b, self.__parameter.getWindow() * 2 + 1 - b):
                c = iteration.getSentencePosition() - self.__parameter.getWindow() + a
                if a != self.__parameter.getWindow() and currentSentence.safeIndex(c):
                    lastWordIndex = self.__vocabulary.getPosition(currentSentence.getWord(c))
                    outputs.addVector(self.__wordVectors.getRowVector(lastWordIndex))
                    cw = cw + 1
            if cw > 0:
                outputs.divide(cw)
                if self.__parameter.isHierarchicalSoftMax():
                    for d in range(currentWord.getCodeLength()):
                        l2 = currentWord.getPoint(d)
                        f = outputs.dotProduct(self.__wordVectorUpdate.getRowVector(l2))
                        if f <= -NeuralNetwork.MAX_EXP or f >= NeuralNetwork.MAX_EXP:
                            continue
                        else:
                            f = self.__expTable[int((f + NeuralNetwork.MAX_EXP) *
                                                    (NeuralNetwork.EXP_TABLE_SIZE // NeuralNetwork.MAX_EXP // 2))]
                        g = (1 - currentWord.getCode(d) - f) * iteration.getAlpha()
                        outputUpdate.addVector(self.__wordVectorUpdate.getRowVector(l2).product(g))
                        self.__wordVectorUpdate.addRowVector(l2, outputs.product(g))
                else:
                    for d in range(self.__parameter.getNegativeSamplingSize() + 1):
                        if d == 0:
                            target = wordIndex
                            label = 1
                        else:
                            target = self.__vocabulary.getTableValue(randrange(self.__vocabulary.getTableSize()))
                            if target == 0:
                                target = randrange(self.__vocabulary.size() - 1) + 1
                            if target == wordIndex:
                                continue
                            label = 0
                        l2 = target
                        f = outputs.dotProduct(self.__wordVectorUpdate.getRowVector(l2))
                        g = self.__calculateG(f, iteration.getAlpha(), label)
                        outputUpdate.addVector(self.__wordVectorUpdate.getRowVector(l2).product(g))
                        self.__wordVectorUpdate.addRowVector(l2, outputs.product(g))
                for a in range(b, self.__parameter.getWindow() * 2 + 1 - b):
                    c = iteration.getSentencePosition() - self.__parameter.getWindow() + a
                    if a != self.__parameter.getWindow() and currentSentence.safeIndex(c):
                        lastWordIndex = self.__vocabulary.getPosition(currentSentence.getWord(c))
                        self.__wordVectors.addRowVector(lastWordIndex, outputUpdate)
            currentSentence = iteration.sentenceUpdate(currentSentence)

    cpdef __trainSkipGram(self):
        """
        Main method for training the SkipGram version of Word2Vec algorithm.
        """
        cdef Iteration iteration
        cdef Sentence currentSentence
        cdef Vector outputs, outputUpdate
        cdef int wordIndex, b, cw, a, c, lastWordIndex, d, l1, l2, target, label
        cdef VocabularyWord currentWord
        cdef double f, g
        iteration = Iteration(self.__corpus, self.__parameter)
        currentSentence = self.__corpus.getSentence(iteration.getSentenceIndex())
        outputs = Vector()
        outputs.initAllSame(self.__parameter.getLayerSize(), 0.0)
        outputUpdate = Vector()
        outputUpdate.initAllSame(self.__parameter.getLayerSize(), 0)
        self.__corpus.shuffleSentences(1)
        while iteration.getIterationCount() < self.__parameter.getNumberOfIterations():
            iteration.alphaUpdate()
            wordIndex = self.__vocabulary.getPosition(currentSentence.getWord(iteration.getSentencePosition()))
            currentWord = self.__vocabulary.getWord(wordIndex)
            outputs.clear()
            outputUpdate.clear()
            b = randrange(self.__parameter.getWindow())
            for a in range(b, self.__parameter.getWindow() * 2 + 1 - b):
                c = iteration.getSentencePosition() - self.__parameter.getWindow() + a
                if a != self.__parameter.getWindow() and currentSentence.safeIndex(c):
                    lastWordIndex = self.__vocabulary.getPosition(currentSentence.getWord(c))
                    l1 = lastWordIndex
                    outputUpdate.clear()
                    if self.__parameter.isHierarchicalSoftMax():
                        for d in range(currentWord.getCodeLength()):
                            l2 = currentWord.getPoint(d)
                            f = self.__wordVectors.getRowVector(l1).dotProduct(self.__wordVectorUpdate.getRowVector(l2))
                            if f <= -NeuralNetwork.MAX_EXP or f >= NeuralNetwork.MAX_EXP:
                                continue
                            else:
                                f = self.__expTable[int((f + NeuralNetwork.MAX_EXP) *
                                                        (NeuralNetwork.EXP_TABLE_SIZE // NeuralNetwork.MAX_EXP // 2))]
                            g = (1 - currentWord.getCode(d) - f) * iteration.getAlpha()
                            outputUpdate.addVector(self.__wordVectorUpdate.getRowVector(l2).product(g))
                            self.__wordVectorUpdate.addRowVector(l2, self.__wordVectors.getRowVector(l1).product(g))
                    else:
                        for d in range(self.__parameter.getNegativeSamplingSize() + 1):
                            if d == 0:
                                target = wordIndex
                                label = 1
                            else:
                                target = self.__vocabulary.getTableValue(randrange(self.__vocabulary.getTableSize()))
                                if target == 0:
                                    target = randrange(self.__vocabulary.size() - 1) + 1
                                if target == wordIndex:
                                    continue
                                label = 0
                            l2 = target
                            f = self.__wordVectors.getRowVector(l1).dotProduct(self.__wordVectorUpdate.getRowVector(l2))
                            g = self.__calculateG(f, iteration.getAlpha(), label)
                            outputUpdate.addVector(self.__wordVectorUpdate.getRowVector(l2).product(g))
                            self.__wordVectorUpdate.addRowVector(l2, self.__wordVectors.getRowVector(l1).product(g))
                    self.__wordVectors.addRowVector(l1, outputUpdate)
            currentSentence = iteration.sentenceUpdate(currentSentence)
