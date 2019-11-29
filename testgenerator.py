from random import randint
import os

MAX_NODES = 100
MIN_NODES = 1

dir = os.path.join(os.getcwd(), 'in')
if not os.path.exists(dir):
    os.mkdir(dir)

for test in range(1, 21):
    file = open('in/in' + str(test) + '.txt', 'w+')
    current_node = 1
    number_of_nodes = randint(MIN_NODES, MAX_NODES)
    number_of_queries = randint(MIN_NODES, number_of_nodes)
    file.write(str(number_of_nodes) + ' ' + str(number_of_queries) + '\n')

    for node in range(2, number_of_nodes+1):
        file.write(str(randint(1, node-1)) + ' ' + str(node) + '\n')

    for _ in range(1, number_of_queries+1):
        file.write(str(randint(1, number_of_nodes)) + ' ' + str(randint(1, number_of_nodes)))
        if _ < number_of_queries:
            file.write('\n')
