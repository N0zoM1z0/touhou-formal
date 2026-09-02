# CE Campaign

Generated: `2026-09-02T040758Z`

This campaign reruns every current SMT-backed symbolic execution lane,
stores the full queue JSON for each lane, then builds a high-priority
counterexample summary from the lane-owned risk labels.

## Totals

- Candidates: 328
- High-priority counterexamples: 209
- Medium-priority semantic surprises: 44
- Controls: 75
- All queues SAT: true
- All concrete replays matched requested paths: true
- Queue elapsed seconds: 510.442

## High-Priority Counterexamples By Lane

| Lane | Candidates | High CE | Matched | Elapsed s |
| --- | ---: | ---: | --- | ---: |
| raw_step | 70 | 45 | true | 94.71 |
| raw_body | 85 | 65 | true | 175.71 |
| int_resolver | 8 | 6 | true | 10.467 |
| int_binary | 39 | 26 | true | 60.498 |
| callret | 41 | 27 | true | 53.54 |
| condcall | 16 | 6 | true | 20.694 |
| boss_int | 18 | 9 | true | 25.035 |
| boss_float | 18 | 7 | true | 27.075 |
| extension | 33 | 18 | true | 42.713 |

## Risk Classes

- `arithmetic-fault`: 18
- `arithmetic-overflow`: 13
- `boss-index-oob-read`: 12
- `boss-null-deref`: 4
- `call-stack-oob-write`: 14
- `call-subtable-oob-read`: 7
- `cursor-out-of-range`: 35
- `cursor-underflow`: 35
- `extension-callback-table-oob-read`: 18
- `liveness`: 35
- `mask-set-default-raw`: 3
- `mask-set-known-selector`: 3
- `ret-child-context-oob-read`: 4
- `ret-stack-oob-read`: 8

## Representative CE Witnesses

| ID | Risk | Oracle | Fixture hex |
| --- | --- | --- | --- |
| `th07:formal-active-bit0:boss-float-index-at-or-past-array` | `boss-index-oob-read` | `out-of-bounds-read` | `000000002c00180000010200000000800000008008000000` |
| `th07:formal-active-bit0:boss-float-index-before-array` | `boss-index-oob-read` | `out-of-bounds-read` | `000000002c001800000102000000008000000080ffffffff` |
| `th07:formal-active-bit0:boss-float-null-deref` | `boss-null-deref` | `null-dereference` | `000000002c001800000102000000008000501c4600000000` |
| `th08:formal-active-bit0:boss-float-index-at-or-past-array` | `boss-index-oob-read` | `out-of-bounds-read` | `000000005700180000010200000000800000008008000000` |
| `th08:override-mask-delta:boss-float-index-at-or-past-array` | `boss-index-oob-read` | `out-of-bounds-read` | `000000005700180000030200000000800000008008000000` |
| `th08:formal-active-bit0:boss-float-index-before-array` | `boss-index-oob-read` | `out-of-bounds-read` | `0000000057001800000102000000008000000080ffffffff` |
| `th08:override-mask-delta:boss-float-index-before-array` | `boss-index-oob-read` | `out-of-bounds-read` | `0000000057001800000302000000008000000080ffffffff` |
| `th07:formal-active-bit0:boss-int-index-at-or-past-array` | `boss-index-oob-read` | `out-of-bounds-read` | `000000002b00180000010200000000800000008008000000` |
| `th07:formal-active-bit0:boss-int-index-before-array` | `boss-index-oob-read` | `out-of-bounds-read` | `000000002b001800000102000000008000000080ffffffff` |
| `th07:formal-active-bit0:boss-int-null-deref` | `boss-null-deref` | `null-dereference` | `000000002b00180000010200000000801027000000000000` |
| `th08:formal-active-bit0:boss-int-index-at-or-past-array` | `boss-index-oob-read` | `out-of-bounds-read` | `000000005600180000010200000000800000008008000000` |
| `th08:override-mask-delta:boss-int-index-at-or-past-array` | `boss-index-oob-read` | `out-of-bounds-read` | `000000005600180000030200000000800000008008000000` |
| `th08:formal-active-bit0:boss-int-index-before-array` | `boss-index-oob-read` | `out-of-bounds-read` | `0000000056001800000102000000008000000080ffffffff` |
| `th08:override-mask-delta:boss-int-index-before-array` | `boss-index-oob-read` | `out-of-bounds-read` | `0000000056001800000302000000008000000080ffffffff` |
| `th08:formal-active-bit0:boss-int-null-deref` | `boss-null-deref` | `null-dereference` | `000000005600180000010200000000801027000000000000` |
| `th08:override-mask-delta:boss-int-null-deref` | `boss-null-deref` | `null-dereference` | `000000005600180000030200000000801027000000000000` |
| `th06:formal-active-bit0:call-lookup-fault` | `call-subtable-oob-read` | `out-of-bounds-read` | `000000002300000000010000ffffffff` |
| `th06:retail-lunatic-bit3:call-lookup-fault` | `call-subtable-oob-read` | `out-of-bounds-read` | `000000002300000000080000ffffffff` |
| `th06:formal-active-bit0:call-stack-write-at-or-past-stack` | `call-stack-oob-write` | `out-of-bounds-write` | `00000000230000000001000000000000` |
| `th06:retail-lunatic-bit3:call-stack-write-at-or-past-stack` | `call-stack-oob-write` | `out-of-bounds-write` | `00000000230000000008000000000000` |

## Residual Blind Spots

- full gameplay side effects through bullets, lasers, EnemyManager/ItemManager runtime state, ANM, rendering, input, and callbacks
- persistent host-runtime interactions beyond the typed boundary of each source-modeled opcode body
- large multi-resource interactions where a retail oracle is easier to observe than to prove
- empirical prioritization of which formally reachable witnesses are retail-visible bugs
