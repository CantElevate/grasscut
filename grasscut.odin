package grasscut

import "core:fmt"
import "core:math/rand"
import "core:strings"
import rl "vendor:raylib"

GRID_WIDTH :: 80
GRID_HEIGHT :: 75
CELL_WIDTH :: 8
CELL_HEIGHT :: 8
UI_X :: 640

grass: [GRID_WIDTH][GRID_HEIGHT]bool
grass_age: [GRID_WIDTH][GRID_HEIGHT]f32
cut_score := 0
radius_cost := 100
radius := 1
Button :: struct {
	rect: rl.Rectangle,
	text: string,
}

main :: proc() {
	rl.InitWindow(800, 600, "Grass Cut")
	defer rl.CloseWindow()
	init_grass()

	swing_timer := f32(0.25)

	radius_button := Button {
		rect = {650, 100, 130, 50},
		text = "Radius +1",
	}

	for !rl.WindowShouldClose() {
		dt := rl.GetFrameTime()
		swing_timer -= dt

		rl.ClearBackground(rl.BLACK)
		grow_grass(dt)

		rl.BeginDrawing()
		cx, cy := mouse_update()
		if rl.IsMouseButtonPressed(rl.MouseButton.LEFT) {
			mouse := rl.GetMousePosition()
			if rl.CheckCollisionPointRec(mouse, radius_button.rect) {
				if cut_score >= radius_cost {
					cut_score -= radius_cost
					radius += 1
					radius_cost *= 2
				}
			}
		}

		if cx >= 0 && cy >= 0 {
			if rl.IsMouseButtonDown(rl.MouseButton.LEFT) && swing_timer <= 0 {
				cut_score += cut_grass(cx, cy, radius)
				swing_timer = 0.50
			}
		}

		///draw shit
		draw_grid()
		draw_ui()
		draw_button(radius_button)
		draw_cursor(cx, cy, radius)

		rl.EndDrawing()
	}
}

draw_button :: proc(button: Button) {
	mouse := rl.GetMousePosition()
	hovered := rl.CheckCollisionPointRec(mouse, button.rect)
	color := rl.DARKGRAY
	if hovered {
		color = rl.GRAY
	}

	rl.DrawRectangleRec(button.rect, color)
	button_string := fmt.tprintf("%s :\n %d", button.text, radius_cost)
	button_text := strings.clone_to_cstring(button_string)

	rl.DrawText(
		cstring(button_text),
		i32(button.rect.x + 10),
		i32(button.rect.y + 10),
		20,
		rl.WHITE,
	)
}

draw_cursor :: proc(cx, cy, radius: int) {
	draw_radius := f32(radius * CELL_WIDTH)
	rl.DrawCircle(
		i32(cx * CELL_WIDTH + CELL_WIDTH / 2),
		i32(cy * CELL_HEIGHT + CELL_HEIGHT / 2),
		draw_radius,
		rl.ColorAlpha(rl.RED, 0.5),
	)
}

mouse_update :: proc() -> (int, int) {
	mouse := rl.GetMousePosition()
	if mouse.x >= UI_X {
		return -1, -1
	}
	return int(mouse.x) / CELL_WIDTH, int(mouse.y) / CELL_HEIGHT
}

cut_grass :: proc(cx, cy, radius: int) -> int {
	cut_count := 0
	for y := cy - radius; y <= cy + radius; y += 1 {
		for x := cx - radius; x <= cx + radius; x += 1 {
			if x < 0 || x >= GRID_WIDTH {
				continue
			}
			if y < 0 || y >= GRID_HEIGHT {
				continue
			}
			dx := x - cx
			dy := y - cy
			if dx * dx + dy * dy <= radius * radius {
				if grass[x][y] {
					grass[x][y] = false
					grass_age[x][y] = rand.float32_range(0, 4)
					cut_count += 1
				}
			}
		}
	}
	return cut_count
}


init_grass :: proc() {
	for y := 0; y < GRID_HEIGHT; y += 1 {
		for x := 0; x < GRID_WIDTH; x += 1 {
			grass[x][y] = true
		}
	}
}

draw_ui :: proc() {
	score_text := fmt.tprintf("Score: %d", cut_score)
	score_cstring := strings.clone_to_cstring(score_text)
	rl.DrawText(cstring(score_cstring), 10, 10, 25, rl.BLACK)
}
draw_grid :: proc() {
	for y := 0; y < GRID_HEIGHT; y += 1 {
		for x := 0; x < GRID_WIDTH; x += 1 {
			if grass[x][y] {
				rl.DrawRectangle(
					i32(x * CELL_WIDTH),
					i32(y * CELL_HEIGHT),
					i32(CELL_WIDTH),
					i32(CELL_HEIGHT),
					rl.GREEN,
				)
			} else {
				rl.DrawRectangle(
					i32(x * CELL_WIDTH),
					i32(y * CELL_HEIGHT),
					i32(CELL_WIDTH),
					i32(CELL_HEIGHT),
					rl.BROWN,
				)
			}
		}
	}
}

grow_grass :: proc(dt: f32) {
	for y := 0; y < GRID_HEIGHT; y += 1 {
		for x := 0; x < GRID_WIDTH; x += 1 {
			if !grass[x][y] {
				grass_age[x][y] += dt
			}

			if grass_age[x][y] >= 5.0 {
				grass[x][y] = true
			}
		}
	}
}
