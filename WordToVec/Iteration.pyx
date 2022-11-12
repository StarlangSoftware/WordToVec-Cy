cdef class Iteration:

    def __init__(self,
                 corpus: CorpusStream,
                 wordToVecParameter: WordToVecParameter):
        """
        Constructor for the Iteration class. Get corpus and parameter as input, sets the corresponding
        parameters.

        PARAMETERS
        ----------
        corpus : Corpus
            Corpus used to train word vectors using Word2Vec algorithm.
        wordToVecParameter : WordToVecParameter
            Parameters of the Word2Vec algorithm.
        """
        self.__corpus = corpus
        self.__word_to_vec_parameter = wordToVecParameter
        self.__word_count = 0
        self.__last_word_count = 0
        self.__word_count_actual = 0
        self.__iteration_count = 0
        self.__sentence_position = 0
        self.__starting_alpha = wordToVecParameter.getAlpha()
        self.__alpha = wordToVecParameter.getAlpha()

    cpdef double getAlpha(self):
        """
        Accessor for the alpha attribute.

        RETURNS
        -------
        float
            Alpha attribute.
        """
        return self.__alpha

    cpdef int getIterationCount(self):
        """
        Accessor for the iterationCount attribute.

        RETURNS
        -------
        int
            IterationCount attribute.
        """
        return self.__iteration_count

    cpdef int getSentencePosition(self):
        """
        Accessor for the sentencePosition attribute.

        RETURNS
        -------
        int
            SentencePosition attribute
        """
        return self.__sentence_position

    cpdef alphaUpdate(self, int totalNumberOfWords):
        """
        Updates the alpha parameter after 10000 words has been processed.
        """
        if self.__word_count - self.__last_word_count > 10000:
            self.__word_count_actual += self.__word_count - self.__last_word_count
            self.__last_word_count = self.__word_count
            self.__alpha = self.__starting_alpha * (1 - self.__word_count_actual /
                                                    (self.__word_to_vec_parameter.getNumberOfIterations() *
                                                     totalNumberOfWords + 1.0))
            if self.__alpha < self.__starting_alpha * 0.0001:
                self.__alpha = self.__starting_alpha * 0.0001

    cpdef Sentence sentenceUpdate(self, Sentence currentSentence):
        """
        Updates sentencePosition, sentenceIndex (if needed) and returns the current sentence processed. If one sentence
        is finished, the position shows the beginning of the next sentence and sentenceIndex is incremented. If the
        current sentence is the last sentence, the system shuffles the sentences and returns the first sentence.

        PARAMETERS
        ----------
        currentSentence : Sentence
            Current sentence processed.

        RETURNS
        -------
        Sentence
            If current sentence is not changed, currentSentence; if changed the next sentence; if next sentence is
            the last sentence; shuffles the corpus and returns the first sentence.
        """
        self.__sentence_position = self.__sentence_position + 1
        if self.__sentence_position >= currentSentence.wordCount():
            self.__word_count += currentSentence.wordCount()
            self.__sentence_position = 0
            sentence = self.__corpus.getSentence()
            if sentence is None:
                self.__iteration_count = self.__iteration_count + 1
                self.__word_count = 0
                self.__last_word_count = 0
                self.__corpus.close()
                self.__corpus.open()
                sentence = self.__corpus.getSentence()
            return sentence
        return currentSentence
