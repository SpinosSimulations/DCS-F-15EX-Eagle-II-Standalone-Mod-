





dofile(LockOn_Options.common_script_path.."devices_defs.lua")
indicator_type	= indicator_types.HELMET
purposes		= {render_purpose.GENERAL, render_purpose.HUD_ONLY_VIEW, render_purpose.GENERAL_AFTER_POSTEFFECTS,
				   render_purpose.HUD_ONLY_VIEW_AFTER_POSTEFFECTS}

page_subsets	= {[1] = LockOn_Options.script_path.."Displays/HMD/page.lua"}
pages			= {{1}}
init_pageID		= 1
