return {
	["misc"] = {
		["dictionary"] = {
			--Config Stuff
			["os_config_header"] = "Config",
			["os_config_end_shock"] = "Shock on loss",
			["os_config_joker"] = "Custom Jokers",
			["k_os_zap"] = "Zap!"
		},
	},
	["descriptions"] = {
		["Joker"] = {
			["j_os_high_voltage"] = {
				["name"] = "High Voltage",
				["text"] = {
					"Gives {X:mult,C:white}X#1#{} Mult",
					"has a {C:green}#2# in #3#{} chance",
                    "to shock you instead",
				},
			},
        },
		["Mod"] = {
			["OpenShock"] = {
				["name"] = "OpenShock",
				["text"] = {
					"Adds a shocking new experience to Balatro"
				}
			}
		}

	},
}
