import test from 'node:test'
import assert from 'node:assert/strict'
import { planRouteReturn } from './mission-route-return.js'

test('return reverses occurrences without duplicating the turnaround or deduplicating repeats', () => {
  const cells = [[0,0],[0,0],[3,4],[0,0],[3,4]], before = structuredClone(cells)
  const plan = planRouteReturn(cells, 2)
  assert.deepEqual(plan.returnLeg, [[0,0],[3,4],[0,0],[0,0]])
  assert.deepEqual(plan.route, [...cells, ...plan.returnLeg])
  assert.deepEqual(plan.distanceM, { outbound: 30, return: 30, total: 60 })
  plan.route[0][0] = 5; plan.returnLeg[0][0] = 8
  assert.deepEqual(cells, before)
  assert.deepEqual(planRouteReturn([[1,1],[1,1]], 20).route, [[1,1],[1,1],[1,1]])
  assert.equal(planRouteReturn([[1,1],[1,1]], 20).distanceM.total, 0)
})

test('return enforces the existing bound and rejects malformed coordinates', () => {
  assert.equal(planRouteReturn(Array.from({ length: 128 }, (_, i) => [0,i]), 1).route.length, 255)
  for (const length of [129,256]) assert.throws(() => planRouteReturn(Array.from({ length }, (_, i) => [0,i]), 1), /256-occurrence/)
  for (const cells of [null, [], [[0,0]], [[0,0],[1]], [[0,0],[-1,0]], [[0,0],[0.1,1]], [[0,0],[Infinity,0]], [[0,0],[1000001,0]]]) assert.throws(() => planRouteReturn(cells, 1), /Correct/)
})

test('unavailable or overflowing distances never manufacture a finite estimate or block exact authoring', () => {
  for (const size of [undefined, null, 0, -1, NaN, Infinity, '20', Number.MAX_VALUE]) {
    const plan = planRouteReturn([[0,0],[1,1]], size)
    assert.equal(plan.distanceM, null); assert.equal(plan.route.length, 3)
  }
  assert.deepEqual(planRouteReturn([[1000000,0],[0,1000000]], 1).route.at(-1), [1000000,0])
})
