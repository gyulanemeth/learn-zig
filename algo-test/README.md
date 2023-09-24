# Algorithmic skills tester

I'm working on a semi-automated evaluation process for evaluating the algorithmic skills for potential future employees.
This is one step in the evaluation, and I would like to do it in a fully automated manner.

The idea is, that I write a framework in zig - that is compiled to WASM - and this framework will evaluate the functions that are written by my future employees.

I wanna test them with multiple excercises, going from easy to hard. There is one caveat though. It has to be ChatGPT-resilliant. So, if it can be done with ChatGPT, then the test makes no sense.

Here are some ideas for the tests:
 - some kind of n2 sort algorithm...
 - some kind of filtering
 - any other array manipulation
 - matrix operations
 - image manipulator algorighms (eg. some part of bluring an image, or rotating an image by 90 degrees)
 - game of life update rules (or other parts of the state update function)
 - minesweeper reveal algorightm

The webassembly module will run the basis of the algorithm, and the candidates will have to write one-one function.

## ChatGPT test

Bubble sort challenge
 - easily solvable with chatgpt
 - I guess it will be the same with any of the famous sorting algorithms

Array manipulation:
 - based on the description, ChatGPT could easily solve them


Game of life:
 - it does something, but I'm not sure that it will work...


Image manipulation algos:
 - chatgpt could easily solve them.


What the fuck shall I test then???
