// 1. Refresh corpus
python3 -c "from rag_pipeline import refresh_corpus; import json; print(json.dumps(refresh_corpus(), indent=2))"
Command: refresh_corpus()
Result: status: success
chunk_count: 19
collection: student_enrolment_enterprise_context
vector_store_status: ready

// 2. Retrieve context
python3 -c "from rag_pipeline import retrieve_context; import json; print(json.dumps(retrieve_context('students enrolled in ASD101', 5), indent=2))"
Query used: "students enrolled in ASD101" (k=5)
Retrieval mode: vector
Retrieval results count: 5

Chunk Source Tier Distance
db_student_8 (Sophia Hall, NET201) enrolment.db tier_1 1.506
db_student_7 (Daniel Green, NET201) enrolment.db tier_1 1.555
db_student_4 (Emma Brown, WEB201) enrolment.db tier_1 1.600
run-report_1 reports/run-report.md tier_2 1.410
boundary-analysis_1 reports/boundary-analysis.md tier_2 1.534

Each result includes chunk_id, source_id, authority_tier, distance and text.

// 3. Answer question
python3 -c "from rag_pipeline import answer_question; import json; print(json.dumps(answer_question('Which students are enrolled in ASD101?', 5), indent=2))"
Query used: "Which students are enrolled in ASD101?" (k=5)
Confidence category: High
Citations provided (5): db_schema, db_student_4, db_student_7 (all enrolment.db, tier_1); boundary-analysis_1, run-report_1 (tier_2)
retrieval_summary: k=5, retrieved_count=5, top_chunk=db_schema

// 4. Run evaluation
python3 rag_eval.py
Query Retrieved Relevant P@5 R@5
students enrolled in ASD101 db_student_8, db_student_7, db_student_4, run-report_1, boundary-analysis_1 run-report_1 0.2 0.5
student count db_student_count, db_student_7, db_student_6, run-report_1, tool-review_1 db_student_count, db_student_7, db_student_6, run-report_1 0.8 1.0
CI report status db_student_10, db_student_3, run-report_1, integration-report_1, boundary-analysis_1 run-report_1, integration-report_1, boundary-analysis_1 0.6 1.0
