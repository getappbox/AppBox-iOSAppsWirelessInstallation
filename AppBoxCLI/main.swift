//
//  main.swift
//  AppBoxCLI
//
//  Created by Vineet Choudhary on 04/09/25.
//  Copyright © 2025 Developer Insider. All rights reserved.
//

import Foundation

var command = AppBoxCLI.parseOrExit()
command.run()
