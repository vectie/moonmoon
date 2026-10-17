import test from 'node:test'
import assert from 'node:assert/strict'
import { planRouteDetour, parseAvoidCells } from './mission-route-detour.js'
const grid = (rows, cols) => ({ available: true, byCell: new Map(Array.from({ length: rows * cols }, (_, i) => [`${Math.floor(i / cols)},${i % cols}`, {}])) })
const heights = (rows, cellSize = 1) => ({ available: true, cellSize, byCell: new Map(rows.flatMap((row, r) => row.map((elevation, c) => [`${r},${c}`, { elevation }]))) })
const limited = maxAbsGrade => ({ mode: 'grade-limited', maxAbsGrade })

test('detour finds deterministic shortest cardinal path around exclusions without mutating inputs', () => {
  const terrain = grid(3, 3), cells = [[0,0],[0,1],[0,2]], original = structuredClone(cells)
  const result = planRouteDetour(terrain, cells, 0, 2, [[0,1]])
  assert.deepEqual(result.path, [[0,0],[1,0],[1,1],[1,2],[0,2]])
  assert.deepEqual(planRouteDetour(terrain, cells, 0, 2, [[0,1]]), result)
  assert.deepEqual(cells, original); assert.equal(terrain.byCell.size, 9)
  result.route[0][0] = 99; assert.deepEqual(cells, original)
})

test('occurrence indices preserve repeated prefix/suffix and warn about exclusions outside selected span', () => {
  const cells = [[0,1],[0,0],[0,1],[0,2],[0,1],[0,0]]
  const result = planRouteDetour(grid(3,3), cells, 1, 3, [[0,1]])
  assert.deepEqual(result.route, [[0,1],[0,0],[1,0],[1,1],[1,2],[0,2],[0,1],[0,0]])
  assert.equal(result.outsideAvoid, 2)
  assert.equal(planRouteDetour(grid(3,3), [[0,0],[0,1]], 0, 1).unchanged, true)
})

test('missing samples and diagonal-only connections do not invent coverage', () => {
  const terrain = grid(1,3); terrain.byCell.delete('0,1')
  assert.throws(() => planRouteDetour(terrain, [[0,0],[0,2]], 0, 1), /No four-neighbor/)
  assert.throws(() => planRouteDetour(terrain, [[0,1],[0,2]], 0, 1), /exact frozen/)
  const diagonal = grid(2,2); diagonal.byCell.delete('0,1'); diagonal.byCell.delete('1,0')
  assert.throws(() => planRouteDetour(diagonal, [[0,0],[1,1]], 0, 1), /No four-neighbor/)
  assert.throws(() => planRouteDetour(grid(2,2), [[0,0],[1,1]], 0, 1, [[0,1],[1,0]]), /No four-neighbor/)
})

test('input bounds, closed endpoints, excluded endpoints and overflow fail closed', () => {
  const terrain = grid(2,2)
  assert.throws(() => planRouteDetour({available:false}, [[0,0],[0,1]],0,1), /unavailable/)
  assert.throws(() => planRouteDetour(terrain, [[0,0],[0,0]],0,1), /closed loops/)
  assert.throws(() => planRouteDetour(terrain, [[0,0],[0,1]],0,1,[[0,0]]), /endpoint/)
  for (const [from,to] of [[1,0],[-1,1],[0,2],[0,.5]]) assert.throws(() => planRouteDetour(terrain, [[0,0],[0,1]],from,to), /occurrence/)
  assert.throws(() => planRouteDetour(grid(1,257), [[0,0],[0,256]],0,1), /256-occurrence/)
  assert.throws(() => planRouteDetour(grid(1,4097), [[0,0],[0,1]],0,1), /4096-sample/)
  assert.deepEqual(parseAvoidCells(' \r\n'), [])
  assert.deepEqual(parseAvoidCells('0,1\r\n1,2'), [[0,1],[1,2]])
  for (const text of ['0,','-1,2','1,2,3','1e1,0','1000001,0',Array(257).fill('1,1').join('\n'),' '.repeat(16385)]) assert.throws(() => parseAvoidCells(text))
})

test('sampled grade chooses shortest eligible shallow route rather than shorter steep route', () => {
  const terrain = heights([[0,10,0],[0,0,0]]), route = [[0,0],[0,2]]
  const snapshot = structuredClone(terrain), cells = structuredClone(route), constraint = limited(0)
  const unrestricted = planRouteDetour(terrain, route, 0, 1, [], { mode: 'unrestricted' })
  assert.deepEqual(unrestricted.path, [[0,0],[0,1],[0,2]])
  assert.deepEqual(unrestricted.constraint, { mode: 'unrestricted' })
  const proposal = planRouteDetour(terrain, route, 0, 1, [], constraint)
  assert.deepEqual(proposal.path, [[0,0],[1,0],[1,1],[1,2],[0,2]])
  assert.deepEqual(proposal.constraint, { mode: 'grade-limited', maxAbsGrade: 0, cellSize: 1, peakAbsGrade: 0 })
  assert.deepEqual(planRouteDetour(terrain, route, 0, 1, [], constraint), proposal)
  assert.deepEqual(terrain, snapshot); assert.deepEqual(route, cells); assert.deepEqual(constraint, limited(0))
  assert.throws(() => planRouteDetour(terrain, route, 0, 1, [[1,1]], constraint), /grade bound/)
  assert.deepEqual(planRouteDetour(terrain, route, 0, 1, [], limited(10)).path, unrestricted.path)
})

test('absolute grade is inclusive at exact bound, symmetric, and zero permits only equal heights', () => {
  const terrain = heights([[0,.5,0]], 2), route = [[0,0],[0,2]]
  assert.deepEqual(planRouteDetour(terrain, route, 0, 1, [], limited(.25)).path, [[0,0],[0,1],[0,2]])
  assert.equal(planRouteDetour(terrain, route, 0, 1, [], limited(.25)).constraint.peakAbsGrade, .25)
  assert.deepEqual(planRouteDetour(terrain, [...route].reverse(), 0, 1, [], limited(.25)).path, [[0,2],[0,1],[0,0]])
  assert.throws(() => planRouteDetour(terrain, route, 0, 1, [], limited(.249999999999)), /grade bound/)
  assert.throws(() => planRouteDetour(terrain, route, 0, 1, [], limited(0)), /grade bound/)
  assert.equal(planRouteDetour(heights([[2,2,2]]), route, 0, 1, [], limited(0)).path.length, 3)
})

test('grade-limited mode never fills unknown cells or changes prefix, suffix and repeated occurrences', () => {
  const terrain = heights([[0,10,0],[0,0,0]])
  const cells = [[99,99],[0,1],[0,0],[0,1],[0,2],[0,1],[99,99]]
  const result = planRouteDetour(terrain, cells, 2, 4, [[0,1]], limited(0))
  assert.deepEqual(result.route, [[99,99],[0,1],[0,0],[1,0],[1,1],[1,2],[0,2],[0,1],[99,99]])
  assert.equal(result.outsideAvoid, 2)
  terrain.byCell.delete('1,1')
  assert.throws(() => planRouteDetour(terrain, [[0,0],[0,2]], 0, 1, [], limited(0)), /No four-neighbor/)
  assert.throws(() => planRouteDetour(terrain, [[1,1],[0,2]], 0, 1, [], limited(0)), /exact frozen/)
  assert.throws(() => planRouteDetour(heights([Array(257).fill(0)]), [[0,0],[0,256]], 0, 1, [], limited(0)), /256-occurrence/)
})

test('invalid bound and frozen geometry fail closed while explicit unrestricted stays grade-independent', () => {
  const cells = [[0,0],[0,1]]
  for (const value of [undefined, null, '', '0', -1, NaN, Infinity, -Infinity]) assert.throws(() => planRouteDetour(heights([[0,1]]), cells, 0, 1, [], limited(value)), /finite nonnegative/)
  for (const value of [null, {}, {mode:'auto'}, {mode:'unrestricted',maxAbsGrade:0}]) assert.throws(() => planRouteDetour(heights([[0,1]]), cells, 0, 1, [], value), /routing/)
  for (const size of [0, -1, null, undefined, NaN, Infinity]) {
    const terrain = heights([[0,0]]); terrain.cellSize = size
    assert.throws(() => planRouteDetour(terrain, cells, 0, 1, [], limited(0)), /cell size/)
  }
  for (const value of [undefined, null, '1', NaN, Infinity, -Infinity]) assert.throws(() => planRouteDetour(heights([[0,value]]), cells, 0, 1, [], limited(1)), /elevations/)
  for (const terrain of [heights([[-Number.MAX_VALUE,Number.MAX_VALUE]]), heights([[0,1]], Number.MIN_VALUE), heights([[0,Number.MIN_VALUE]], Number.MAX_VALUE)]) assert.throws(() => planRouteDetour(terrain, cells, 0, 1, [], limited(1)), /arithmetic/)
  assert.deepEqual(planRouteDetour(grid(1,2), cells, 0, 1, [], {mode:'unrestricted'}).path, cells)
})
