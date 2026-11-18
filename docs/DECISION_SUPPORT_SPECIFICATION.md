# Mars Pathfinder — Autonomous Decision-Support Specification

## 1. Grounding Principles
The Mars Pathfinder AI Assistant is designed as an advisory decision-support instrument. Under no circumstances does the assistant possess unilateral executive authority to dispatch physical vehicles, alter habitat environmental controls, or override human commander directives.

## 2. Safety Tiers & Action Authority Matrix
| Safety Classification | Permitted Actions | Human Approval Required? | System Behavior |
| :--- | :--- | :--- | :--- |
| `INFORMATION_ONLY` | Read telemetry, status summaries, science data | No | Directly rendered in UI chat stream |
| `RECOMMENDATION` | Route suggestions, resource conservation advice | No (Advisory) | Formulates 10-point recommendation card |
| `SIMULATION_ACTION` | Non-destructive what-if state branch evaluations | No | Clones mission state; isolates deltas |
| `REQUIRES_HUMAN_APPROVAL` | Crew rendezvous dispatches, habitat airlock seals | **YES** | Halts execution until explicit UI approval |
| `NOT_AUTHORIZED` | Arbitrary shell execution, raw database mutations | Blocked | Tool execution rejected with audit log |

## 3. Mandatory 10-Point Recommendation Structure
Every operational recommendation emitted by the decision-support engine strictly comprises:
1. **Situation**: Summary of the operational state requiring intervention.
2. **Relevant Evidence**: Quantifiable telemetry or observation points.
3. **Data Source**: Specific sensor subsystem or orbital dataset.
4. **Observation Timestamp**: Temporal tag of data acquisition.
5. **Risk Assessment**: Classified risk severity (`LOW`, `MODERATE`, `HIGH`, `CRITICAL`).
6. **Recommended Action**: Primary recommended intervention course.
7. **Alternative Action**: Fallback or conservative contingency option.
8. **Expected Consequences**: Projected operational and life-support outcome.
9. **Uncertainty Score**: Degree of epistemic uncertainty (0.0 to 1.0).
10. **Human Approval Requirement**: Explicit gate status and authorization token.
