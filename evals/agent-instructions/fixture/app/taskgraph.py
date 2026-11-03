from collections import defaultdict, deque


class TaskGraph:
    def __init__(self):
        self._edges = defaultdict(set)
        self._nodes = set()

    def add_edge(self, before, after):
        self._nodes.update((before, after))
        self._edges[before].add(after)

    def order(self):
        indegree = {node: 0 for node in self._nodes}
        for targets in self._edges.values():
            for target in targets:
                indegree[target] += 1
        queue = deque(sorted(node for node, degree in indegree.items() if degree == 0))
        result = []
        while queue:
            node = queue.popleft()
            result.append(node)
            for target in sorted(self._edges[node]):
                indegree[target] -= 1
                if indegree[target] == 0:
                    queue.append(target)
        if len(result) != len(self._nodes):
            raise ValueError("cycle detected")
        return result
