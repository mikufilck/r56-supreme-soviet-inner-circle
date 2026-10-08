"""Build static Supreme Soviet job idea variants from the S3 source snapshot."""

import json
import re
from collections import deque
from decimal import Decimal
from pathlib import Path


ROOT = Path(__file__).resolve().parent.parent
SPEC = json.loads((ROOT / "build/hof-ic-role-spec.json").read_text(encoding="utf-8"))
MOD = ROOT / "mod/heart_of_iron"


def prerequisites(focus):
    groups = []
    pending = []
    for item in focus.get("P", []):
        if isinstance(item, list):
            if pending:
                groups.append(pending)
                pending = []
            groups.append(item)
        else:
            pending.append(item)
    if pending:
        groups.append(pending)
    return groups


def reachable_states(foci, branch):
    ids = [f["Id"] for f in foci]
    index = {value: i for i, value in enumerate(ids)}
    groups = [prerequisites(f) for f in foci]
    mutex = [index.get(f.get("Mut")) for f in foci]
    branch_index = list(dict.fromkeys(index[value] for value in branch if value in index))
    earlier_branch_bits = {}
    prefix = 0
    for i in branch_index:
        earlier_branch_bits[i] = prefix
        prefix |= 1 << i
    queue = deque([0])
    states = {0}
    while queue:
        mask = queue.popleft()
        for i in range(len(foci)):
            bit = 1 << i
            if mask & bit or (mutex[i] is not None and mask & (1 << mutex[i])):
                continue
            if any(mask & (1 << j) and mutex[j] == i for j in range(len(foci))):
                continue
            if i in earlier_branch_bits and mask & earlier_branch_bits[i] != earlier_branch_bits[i]:
                continue
            if all(any(p == "__entry__" or (p in index and mask & (1 << index[p])) for p in group) for group in groups[i]):
                next_mask = mask | bit
                if next_mask not in states:
                    states.add(next_mask)
                    queue.append(next_mask)
    return states


def block_end(lines, start):
    """Return the line after a generated Paradox block, starting at its opener."""
    depth = 0
    for pos in range(start, len(lines)):
        code = lines[pos].split("#", 1)[0]
        depth += code.count("{") - code.count("}")
        if depth == 0 and pos >= start:
            return pos + 1
    raise ValueError(f"Unclosed block at line {start + 1}")


def replace_named_block(source, name, replacement):
    lines = source.splitlines(keepends=True)
    opener = re.compile(r"^\s*" + re.escape(name) + r"\s*=\s*\{\s*$")
    matches = [i for i, line in enumerate(lines) if opener.match(line)]
    if len(matches) != 1:
        raise ValueError(f"Expected one block for {name}, found {len(matches)}")
    start = matches[0]
    end = block_end(lines, start)
    return "".join(lines[:start]) + replacement + "".join(lines[end:])


def replace_defined_text(source, name, replacement):
    lines = source.splitlines(keepends=True)
    matches = [i for i, line in enumerate(lines) if line.strip() == f"name = {name}"]
    if len(matches) != 1 or matches[0] == 0 or lines[matches[0] - 1].strip() != "defined_text = {":
        raise ValueError(f"Expected one defined_text for {name}")
    start = matches[0] - 1
    end = block_end(lines, start)
    return "".join(lines[:start]) + replacement + "".join(lines[end:])


def tier_for_state(roster, focus_ids):
    for gate in roster.get("RankGates") or []:
        match = re.fullmatch(r"has_completed_focus\s*=\s*(\S+)", gate["Gate"])
        if match and match.group(1) in focus_ids:
            return next(t for t in roster["Tiers"] if t["Id"] == gate["Id"])
    return roster["Tiers"][0]


def numbers_for_state(roster, foci, mask, tier):
    values = {"political_power_gain": Decimal(str(tier["Pp"]))}
    for row in roster["Mod"] or []:
        key, value = [part.strip() for part in row.split("=", 1)]
        values[key] = Decimal(value)
    for row in tier.get("Add") or []:
        key, value = [part.strip() for part in row.split("=", 1)]
        values[key] = Decimal(value)
    for i, focus in enumerate(foci):
        if mask & (1 << i):
            for row in focus.get("V") or []:
                key, _, value = row.split("|")
                values[key] = values.get(key, Decimal(0)) + Decimal(value)
    return values


def state_id(key, mask):
    return f"hof_ic_role_{key}_{mask:x}"


def done_flag(focus_id):
    return f"hof_ic_done_{focus_id}"


def build():
    roster = {person["Key"]: person for person in SPEC["Roster"]}
    lines_by_key = {line["Key"]: line["Line"] for line in SPEC["Lines"]}
    states_by_key = {
        key: sorted(reachable_states(foci, roster[key]["Branch"]))
        for key, foci in lines_by_key.items()
    }
    for key, states in states_by_key.items():
        covered = 0
        for mask in states:
            covered |= mask
        expected = (1 << len(lines_by_key[key])) - 1
        if covered != expected:
            missing = [focus["Id"] for i, focus in enumerate(lines_by_key[key]) if not covered & (1 << i)]
            raise ValueError(f"Unreachable role bonuses for {key}: {missing}")
    idea_lines = ["# Generated from gen-hof-ic-s3.ps1; personal bonuses belong to the current job idea.", "ideas = {", "\thidden_ideas = {"]
    loc_lines = ["l_simp_chinese:"]
    effect_lines = ["# Generated static job idea selection and removal."]
    all_variant_ids = {}
    for key, foci in lines_by_key.items():
        person = roster[key]
        states = states_by_key[key]
        variant_ids = []
        for mask in states:
            focus_ids = {focus["Id"] for i, focus in enumerate(foci) if mask & (1 << i)}
            tier = tier_for_state(person, focus_ids)
            variant = state_id(key, mask)
            variant_ids.append(variant)
            mods = numbers_for_state(person, foci, mask, tier)
            idea_lines += [f"\t\t{variant} = {{", "\t\t\tallowed = { always = no }", "\t\t\tremoval_cost = -1", "\t\t\tmodifier = {"]
            idea_lines += [f"\t\t\t\t{mod} = {value}" for mod, value in mods.items() if value]
            idea_lines += ["\t\t\t}", "\t\t}"]
            loc_lines.append(f' {variant}:0 "{tier["Zh"]}"')
        all_variant_ids[key] = variant_ids
        # Removing a member must remove every static stage, including legacy tier ideas.
        effect_lines.append(f"hof_ic_role_remove_{key} = {{")
        for idea in [t["Id"] for t in person["Tiers"]] + variant_ids:
            effect_lines.append(f"\tif = {{ limit = {{ has_idea = {idea} }} remove_ideas = {idea} }}")
        effect_lines += ["}", ""]
        effect_lines.append(f"hof_ic_role_refresh_{key} = {{")
        effect_lines.append(f"\thof_ic_role_remove_{key} = yes")
        effect_lines.append(f"\tif = {{")
        effect_lines.append(f"\t\tlimit = {{ hof_ic_seated_{key} = yes }}")
        for n, mask in enumerate(states):
            keyword = "if" if n == 0 else "else_if"
            effect_lines.append(f"\t\t{keyword} = {{")
            effect_lines.append("\t\t\tlimit = {")
            for i, focus in enumerate(foci):
                expr = f"has_country_flag = {done_flag(focus['Id'])}"
                if not mask & (1 << i):
                    expr = f"NOT = {{ {expr} }}"
                effect_lines.append(f"\t\t\t\t{expr}")
            effect_lines += ["\t\t\t}", f"\t\t\tadd_ideas = {state_id(key, mask)}", "\t\t}"]
        effect_lines += ["\t\telse = {", f"\t\t\tadd_ideas = {state_id(key, 0)}", "\t\t}", "\t}", "}", ""]
    effect_lines += ["hof_ic_role_migrate_all = {"]
    for foci in lines_by_key.values():
        for focus in foci:
            effect_lines.append(
                f"\tif = {{ limit = {{ has_completed_focus = {focus['Id']} }} "
                f"set_country_flag = {done_flag(focus['Id'])} }}"
            )
    for person in SPEC["Roster"]:
        effect_lines.append(f"\thof_ic_role_refresh_{person['Key']} = yes")
    effect_lines += ["}", ""]
    idea_lines += ["\t}", "}"]
    (MOD / "common/ideas/hof_ic_role_variants.txt").write_text("\n".join(idea_lines) + "\n", encoding="utf-8")
    (MOD / "common/scripted_effects/hof_ic_role_effects.txt").write_text("\n".join(effect_lines) + "\n", encoding="utf-8")
    (MOD / "localisation/simp_chinese/hof_ic_role_l_simp_chinese.yml").write_text("\n".join(loc_lines) + "\n", encoding="utf-8-sig")
    def migration(indent, include_tag):
        pad = "\t" * indent
        tag = "tag = SOV " if include_tag else ""
        return [
            f"{pad}if = {{",
            f"{pad}\tlimit = {{ {tag}has_completed_focus = hof_ic_commissar NOT = {{ has_country_flag = hof_ic_role_ideas_migrated_v2 }} }}",
            f"{pad}\thof_ic_role_migrate_all = yes",
            f"{pad}\tset_country_flag = hof_ic_role_ideas_migrated_v2",
            f"{pad}}}",
        ]

    on_actions = [
        "# Restore static job ideas in existing saves on startup or the first weekly tick.",
        "on_actions = {", "\ton_startup = {", "\t\teffect = {", "\t\t\tSOV = {",
        *migration(4, False),
        "\t\t\t}", "\t\t}", "\t}",
        "\ton_weekly = {", "\t\teffect = {",
        *migration(3, True),
        "\t\t}", "\t}", "}",
    ]
    (MOD / "common/on_actions/hof_ic_role_on_actions.txt").write_text(
        "\n".join(on_actions) + "\n", encoding="utf-8"
    )

    effect_path = MOD / "common/scripted_effects/hof_ic_scripted_effects.txt"
    effects = effect_path.read_text(encoding="utf-8")
    # Retain the established external API, but delegate to static role variants.
    appoint = ["hof_ic_add_appointee_idea = {"]
    for n, person in enumerate(SPEC["Roster"]):
        key = person["Key"]
        keyword = "if" if n == 0 else "else_if"
        appoint.append(f"\t{keyword} = {{ limit = {{ check_variable = {{ hof_ic_appointing = {person['Idx']} }} }} hof_ic_role_refresh_{key} = yes }}")
    appoint += ["}", ""]
    effects = replace_named_block(effects, "hof_ic_add_appointee_idea", "\n".join(appoint))
    for person in SPEC["Roster"]:
        key = person["Key"]
        effects = replace_named_block(effects, f"hof_ic_idea_{key}_sync_rank", f"hof_ic_idea_{key}_sync_rank = {{\n\thof_ic_role_refresh_{key} = yes\n}}\n")
    for seat in range(1, 8):
        block = [f"hof_ic_remove_slot_{seat}_idea = {{"]
        for n, person in enumerate(SPEC["Roster"]):
            key = person["Key"]
            keyword = "if" if n == 0 else "else_if"
            block.append(f"\t{keyword} = {{ limit = {{ check_variable = {{ hof_ic_slot_{seat} = {person['Idx']} }} }} hof_ic_role_remove_{key} = yes }}")
        block += ["}", ""]
        effects = replace_named_block(effects, f"hof_ic_remove_slot_{seat}_idea", "\n".join(block))
    effect_path.write_text(effects, encoding="utf-8")

    script_path = MOD / "common/scripted_localisation/hof_ic_scripted_loc.txt"
    scripted = script_path.read_text(encoding="utf-8")
    for seat in range(1, 8):
        block = ["defined_text = {", f"\tname = hof_ic_slot_{seat}_dm_desc"]
        for person in SPEC["Roster"]:
            key = person["Key"]
            for variant in all_variant_ids[key]:
                block += ["\ttext = {", f"\t\ttrigger = {{ check_variable = {{ hof_ic_slot_{seat} = {person['Idx']} }} has_idea = {variant} }}", f"\t\tlocalization_key = idea_desc|{variant}", "\t}"]
            for tier in person["Tiers"]:
                block += ["\ttext = {", f"\t\ttrigger = {{ check_variable = {{ hof_ic_slot_{seat} = {person['Idx']} }} has_idea = {tier['Id']} }}", f"\t\tlocalization_key = idea_desc|{tier['Id']}", "\t}"]
        block += ["\ttext = { localization_key = hof_ic_dm_desc_fallback }", "}", ""]
        scripted = replace_defined_text(scripted, f"hof_ic_slot_{seat}_dm_desc", "\n".join(block))
    script_path.write_text(scripted, encoding="utf-8")

    inject_path = ROOT / "build/inject-sov-seats.txt"
    inject = inject_path.read_text(encoding="utf-8")
    for key, foci in lines_by_key.items():
        for focus in foci:
            if not focus.get("V"):
                continue
            pattern = re.compile(r"(?ms)(^focus = \{\n\tid = " + re.escape(focus["Id"]) + r"\b.*?)(?=^focus = \{|\Z)")
            match = pattern.search(inject)
            if not match:
                raise ValueError(f"Missing generated focus {focus['Id']}")
            old = match.group(1)
            if f"hidden_effect = {{ hof_ic_role_refresh_{key} = yes }}" not in old:
                raise ValueError(f"Missing static job refresh in {focus['Id']}")
            if f"hidden_effect = {{ set_country_flag = {done_flag(focus['Id'])} }}" not in old:
                raise ValueError(f"Missing completion flag in {focus['Id']}")
            if old.index(f"set_country_flag = {done_flag(focus['Id'])}") > old.index(f"hof_ic_role_refresh_{key} = yes"):
                raise ValueError(f"Completion flag is too late in {focus['Id']}")
    inject = re.sub(r"(?m)^\t\t\t# .*个人数值容器.*\n\t\t\tadd_dynamic_modifier = \{ modifier = hof_ic_[a-z_]+_dm \}\n", "", inject)
    if re.search(r"add_dynamic_modifier = \{ modifier = hof_ic_(?!supreme_soviet)[a-z_]+_dm \}", inject):
        raise ValueError("A personal dynamic modifier is still attached")
    # HOI4 resolves relative_position_id only against focuses declared earlier.
    # The commissar focus is generated last; move its whole block ahead of seats.
    lines = inject.splitlines(keepends=True)
    commissioner = [i for i, line in enumerate(lines) if line.strip() == "id = hof_ic_commissar"]
    if len(commissioner) != 1 or lines[commissioner[0] - 1].strip() != "focus = {":
        raise ValueError("Cannot locate commissar focus for ordering")
    start = commissioner[0] - 1
    end = block_end(lines, start)
    commissar_block = lines[start:end]
    del lines[start:end]
    first_focus = next(i for i, line in enumerate(lines) if line.strip() == "focus = {")
    lines[first_focus:first_focus] = commissar_block + ["\n"]
    inject = "".join(lines)
    inject_path.write_text(inject, encoding="utf-8")

    # Existing saves may retain these modifiers. Keep their IDs as inert definitions.
    retired = ["# Former personal dynamic modifiers; inert for compatibility with existing saves."]
    for line in SPEC["Lines"]:
        retired += [f"{line['DmId']} = {{", "\tenable = { always = no }", "}"]
    (MOD / "common/dynamic_modifiers/hof_ic_retired_personal_dm.txt").write_text("\n".join(retired) + "\n", encoding="utf-8")
    for line in SPEC["Lines"]:
        # The former files are generated by S3 before this post-pass, then retired.
        name = MOD / "common/dynamic_modifiers" / line["File"]
        if name.exists():
            name.unlink()
    bonus_script = MOD / "common/scripted_localisation/hof_ic_bonus_scripted_loc.txt"
    if bonus_script.exists():
        bonus_script.unlink()
    roster_loc = MOD / "localisation/simp_chinese/hof_ic_roster_l_simp_chinese.yml"
    roster_text = roster_loc.read_text(encoding="utf-8-sig")
    roster_text = re.sub(r"(?m)^ hof_ic_bonus_[^\n]*\n", "", roster_text)
    roster_loc.write_text(roster_text, encoding="utf-8-sig")
    return sum(len(states) for states in states_by_key.values())


if __name__ == "__main__":
    print(f"Generated {build()} static job idea variants")
