
dofile(LockOn_Options.common_script_path.."devices_defs.lua")
indicator_type	= indicator_types.COLLIMATOR
purposes		= {render_purpose.GENERAL, render_purpose.HUD_ONLY_VIEW}

page_subsets	= {[1] = LockOn_Options.script_path.."Displays/HUD/page.lua"}
pages			= {{1}}
init_pageID		= 1
