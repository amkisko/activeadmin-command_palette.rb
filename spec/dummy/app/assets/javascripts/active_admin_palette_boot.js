import "active_admin"
import { Application } from "@hotwired/stimulus"
import CommandPaletteController from "controllers/activeadmin_command_palette/command_palette_controller"

const application = Application.start()
application.register("activeadmin-command-palette--command-palette", CommandPaletteController)
