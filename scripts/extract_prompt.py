import json

transcript_path = r'C:\Users\NV LAP\.gemini\antigravity\brain\6d9df477-31e1-43fa-a3cb-cd8a98582a01\.system_generated\logs\transcript.jsonl'
full_path = r'C:\Users\NV LAP\.gemini\antigravity\brain\6d9df477-31e1-43fa-a3cb-cd8a98582a01\.system_generated\logs\transcript_full.jsonl'

with open(transcript_path, 'r', encoding='utf-8') as f:
    for idx, line in enumerate(f):
        data = json.loads(line)
        content = data.get('content', '')
        if data.get('source') == 'USER_EXPLICIT' and 'second-generation optimization' in content:
            print(f"Found user prompt at step {data.get('step_index')}, line {idx}")
            with open(full_path, 'r', encoding='utf-8') as f_full:
                for idx2, line2 in enumerate(f_full):
                    if idx2 == idx:
                        full_data = json.loads(line2)
                        with open('user_prompt_turn9.txt', 'w', encoding='utf-8') as out:
                            out.write(full_data.get('content', ''))
                        print(f"Wrote full user prompt ({len(full_data.get('content', ''))} chars) to user_prompt_turn9.txt")
                        break
            break
