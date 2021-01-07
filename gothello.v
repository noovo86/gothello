module main

import gg
import gx
import sokol.sapp
import os

struct App {
mut:
	first         int
	turn          int
	vic           int
	inv           int
	not           int
	gg            &gg.Context
	tiles         [][]int
	sol           [][]int
	// UI
	window_width  int
	window_height int
	tilenum       int
	pos_x         int
	pos_y         int
	tile_colors   []gx.Color
	prturn        []string
}

fn main() {
	mut app := &App{
		tilenum: 9 // tile number of raw and column
		first: 1
		turn: 1
		pos_x: 4
		pos_y: 4
		window_width: 800
		window_height: 800
		gg: 0
		tile_colors: [
			gx.rgb(168, 168, 168),
			/* def */
			gx.rgb(217, 217, 217),
			/* white */
			gx.rgb(65, 65, 65),
			/* black */
		]
		tiles: [][]int{len: 9, init: []int{len: 9}}
		sol: [][]int{len: 9, init: []int{len: 9}}
		prturn: [
			'White.',
			'Black. ',
		]
	}
	app.gg = gg.new_context(
		bg_color: gx.rgb(250, 250, 250)
		width: app.window_width
		height: app.window_height
		use_ortho: true
		create_window: true
		window_title: 'Gothello'
		frame_fn: frame
		event_fn: on_event
		user_data: app
		font_path: os.resource_abs_path('./mplus-1p-light.ttf')
	)
	app.gg.run()
}

fn frame(app &App) {
	app.gg.begin()
	app.draw()
	app.gg.end()
}

// processing when resized
fn (mut app App) resize() {
	mut s := sapp.dpi_scale()
	if s == 0.0 {
		s = 1.0
	}
	app.window_width = int(sapp.width() / s)
	app.window_height = int(sapp.height() / s)
}

// drawing tile and text
fn (app &App) draw() {
	w := app.window_width
	h := app.window_height - app.window_height / 15
	n := app.tilenum
	mut pad_w := 0
	mut pad_h := 0
	if w > h {
		pad_w = (w - h) / 2 + h / 30
		pad_h = h / 30 + app.window_height / 15
	} else {
		pad_h = (h - w) / 2 + w / 30 + app.window_height / 15
		pad_w = w / 30
	}
	mw := w - pad_w * 2
	mh := mw
	tw := mw / n - mw / (10 * n) * 2
	th := tw
	xoffset := pad_w + mw / (10 * n)
	yoffset := pad_h + mw / (10 * n)
	app.gg.draw_rect(pad_w + mw - mh / 20 * 3, pad_h - mh / 13, mw / 20 * 3, mh / 15,
		app.tile_colors[app.turn])
	app.gg.draw_text(w / 2, pad_h - mh / 10, 'Gotthelo', align: .center, color: app.tile_colors[2], size: mh /
			10)
	texval := app.prturn[app.turn - 1]
	mut texcol := 2
	if app.turn == 2 {
		texcol = 1
	}
	app.gg.draw_text(pad_w + mw, pad_h - mh / 13, texval, align: .right, color: app.tile_colors[texcol], size: mh /
			15)
	app.gg.draw_rect(xoffset + mw / n * app.pos_x - tw / 20, yoffset + mh / n * app.pos_y - th / 20,
		tw + tw / 10, th + th / 10, gx.rgb(255, 133, 133))
	mut so := 0
	for y in 0 .. n {
		for x in 0 .. n {
			app.gg.draw_rect(xoffset + mw / n * x, yoffset + mh / n * y, tw, th, app.tile_colors[app.tiles[x][y]])
			if app.sol[x][y] != 0 {
				if app.tiles[x][y] == 1 {
					so = 2
				} else {
					so = 1
				}
				app.gg.draw_rect(xoffset + mw / n * x + tw / 5 * 2, yoffset + mh / n * y +
					th / 5 * 2, tw / 5, th / 5, app.tile_colors[so])
			}
		}
	}
	if app.vic == 1 {
		app.gg.draw_rect(pad_w, pad_h + mh / 5 * 2, mw, mh / 5, gx.rgb(255, 133, 133))
		app.gg.draw_text(pad_w + mw / 2, pad_h + mh / 5 * 2, 'The winner is $texval',
			align: .center, color: gx.black, size: mh / 7)
		app.gg.draw_text(pad_w + mw / 2, pad_h + mh / 5 * 2 + mh / 8, "Press 'space' to restart",
			align: .center, color: gx.black, size: mh / 14)
	}
}

// Stop the tiles at the edges.
fn (mut app App) tilestop() {
	if app.pos_x > (app.tilenum - 1) {
		app.pos_x = app.tilenum - 1
	} else if app.pos_x < 0 {
		app.pos_x = 0
	}
	if app.pos_y > (app.tilenum - 1) {
		app.pos_y = app.tilenum - 1
	} else if app.pos_y < 0 {
		app.pos_y = 0
	}
}

// respectively key processing
fn (mut app App) up() {
	posx := app.pos_x
	posy := app.pos_y
	app.pos_y--
	for app.pos_y >= 0 {
		if app.tiles[app.pos_x][app.pos_y] == 0 || app.tiles[app.pos_x][app.pos_y] == app.turn {
			break
		}
		app.pos_y--
	}
	app.tilestop()
	if app.tiles[app.pos_x][app.pos_y] != 0 && app.tiles[app.pos_x][app.pos_y] != app.turn {
		app.pos_x = posx
		app.pos_y = posy
	}
}

fn (mut app App) left() {
	posx := app.pos_x
	posy := app.pos_y
	app.pos_x--
	for app.pos_x >= 0 {
		if app.tiles[app.pos_x][app.pos_y] == 0 || app.tiles[app.pos_x][app.pos_y] == app.turn {
			break
		}
		app.pos_x--
	}
	app.tilestop()
	if app.tiles[app.pos_x][app.pos_y] != 0 && app.tiles[app.pos_x][app.pos_y] != app.turn {
		app.pos_x = posx
		app.pos_y = posy
	}
}

fn (mut app App) down() {
	posx := app.pos_x
	posy := app.pos_y
	app.pos_y++
	for app.pos_y <= (app.tilenum - 1) {
		if app.tiles[app.pos_x][app.pos_y] == 0 || app.tiles[app.pos_x][app.pos_y] == app.turn {
			break
		}
		app.pos_y++
	}
	app.tilestop()
	if app.tiles[app.pos_x][app.pos_y] != 0 && app.tiles[app.pos_x][app.pos_y] != app.turn {
		app.pos_x = posx
		app.pos_y = posy
	}
}

fn (mut app App) right() {
	posx := app.pos_x
	posy := app.pos_y
	app.pos_x++
	for app.pos_x <= (app.tilenum - 1) {
		if app.tiles[app.pos_x][app.pos_y] == 0 || app.tiles[app.pos_x][app.pos_y] == app.turn {
			break
		}
		app.pos_x++
	}
	app.tilestop()
	if app.tiles[app.pos_x][app.pos_y] != 0 && app.tiles[app.pos_x][app.pos_y] != app.turn {
		app.pos_x = posx
		app.pos_y = posy
	}
}

fn (mut app App) space() {
	mut backup := app.tiles.clone()
	if app.tiles[app.pos_x][app.pos_y] == 0 {
		backup[app.pos_x][app.pos_y] = app.turn
		app.inv = 0
		app.not = 0
		mut inv_1 := 0
		mut inv_2 := 0
		mut inv_3 := 0
		mut inv_4 := 0
		mut inv_5 := 0
		mut inv_6 := 0
		mut inv_7 := 0
		mut inv_8 := 0
		mut vic := 0
		mut n := 0
		mut sx := 0
		mut ex := 3
		mut sy := 0
		mut ey := 3
		if app.pos_x == 0 {
			sx = 1
		} else if app.pos_x == (app.tilenum - 1) {
			ex = 2
		}
		if app.pos_y == 0 {
			sy = 1
		} else if app.pos_y == (app.tilenum - 1) {
			ey = 2
		}
		for y in sy .. ey {
			for x in sx .. ex {
				if x != 1 || y != 1 {
					if backup[app.pos_x + x - 1][app.pos_y + y - 1] != app.turn &&
						backup[app.pos_x + x - 1][app.pos_y + y - 1] != 0 {
						n = y * 3 + x + 1
						if n == 1 {
							inv_1 = 1
						}
						if n == 2 {
							inv_2 = 1
						}
						if n == 3 {
							inv_3 = 1
						}
						if n == 4 {
							inv_4 = 1
						}
						if n == 6 {
							inv_5 = 1
						}
						if n == 7 {
							inv_6 = 1
						}
						if n == 8 {
							inv_7 = 1
						}
						if n == 9 {
							inv_8 = 1
						}
					}
				}
			}
		}
		println('\n$inv_1,$inv_2,$inv_3,$inv_4,$inv_5,$inv_6,$inv_7,$inv_8')
		if inv_1 == 1 {
			backup = app.inv_1(backup)
		}
		if inv_2 == 1 {
			backup = app.inv_2(backup)
		}
		if inv_3 == 1 {
			backup = app.inv_3(backup)
		}
		if inv_4 == 1 {
			backup = app.inv_4(backup)
		}
		if inv_5 == 1 {
			backup = app.inv_5(backup)
		}
		if inv_6 == 1 {
			backup = app.inv_6(backup)
		}
		if inv_7 == 1 {
			backup = app.inv_7(backup)
		}
		if inv_8 == 1 {
			backup = app.inv_8(backup)
		}
		vic = app.victory(backup)
		println('vic:$vic')
		println('inv:$app.inv')
		if vic == 1 && app.inv == 1 {
			println('false')
		} else if app.not == 1 {
			println('false')
		} else {
			app.est()
			println('est')
		}
	} else if app.tiles[app.pos_x][app.pos_y] == app.turn && app.sol[app.pos_x][app.pos_y] != 1 {
		app.sol[app.pos_x][app.pos_y] = 1
		app.turn++
		if app.turn > 2 {
			app.turn = 1
		}
	}
}

fn (mut app App) est() {
	app.tiles[app.pos_x][app.pos_y] = app.turn
	if app.first == 1 && app.turn == 2 {
		app.sol[app.pos_x][app.pos_y] = 1
		app.first = 0
	}
	app.inv = 0
	mut inv_1 := 0
	mut inv_2 := 0
	mut inv_3 := 0
	mut inv_4 := 0
	mut inv_5 := 0
	mut inv_6 := 0
	mut inv_7 := 0
	mut inv_8 := 0
	mut vic := 0
	mut n := 0
	mut sx := 0
	mut ex := 3
	mut sy := 0
	mut ey := 3
	if app.pos_x == 0 {
		sx = 1
	} else if app.pos_x == (app.tilenum - 1) {
		ex = 2
	}
	if app.pos_y == 0 {
		sy = 1
	} else if app.pos_y == (app.tilenum - 1) {
		ey = 2
	}
	for y in sy .. ey {
		for x in sx .. ex {
			if x != 1 || y != 1 {
				if app.tiles[app.pos_x + x - 1][app.pos_y + y - 1] != app.turn &&
					app.tiles[app.pos_x + x - 1][app.pos_y + y - 1] != 0 {
					n = y * 3 + x + 1
					if n == 1 {
						inv_1 = 1
					}
					if n == 2 {
						inv_2 = 1
					}
					if n == 3 {
						inv_3 = 1
					}
					if n == 4 {
						inv_4 = 1
					}
					if n == 6 {
						inv_5 = 1
					}
					if n == 7 {
						inv_6 = 1
					}
					if n == 8 {
						inv_7 = 1
					}
					if n == 9 {
						inv_8 = 1
					}
				}
			}
		}
	}
	if inv_1 == 1 {
		app.tiles = app.inv_1(app.tiles)
	}
	if inv_2 == 1 {
		app.tiles = app.inv_2(app.tiles)
	}
	if inv_3 == 1 {
		app.tiles = app.inv_3(app.tiles)
	}
	if inv_4 == 1 {
		app.tiles = app.inv_4(app.tiles)
	}
	if inv_5 == 1 {
		app.tiles = app.inv_5(app.tiles)
	}
	if inv_6 == 1 {
		app.tiles = app.inv_6(app.tiles)
	}
	if inv_7 == 1 {
		app.tiles = app.inv_7(app.tiles)
	}
	if inv_8 == 1 {
		app.tiles = app.inv_8(app.tiles)
	}
	vic = app.victory(app.tiles)
	if vic == 1 {
		app.vic = 1
	} else if vic == 0 {
		app.turn++
		if app.turn > 2 {
			app.turn = 1
		}
	}
}

fn (mut app App) victory(tiles [][]int) int {
	mut o := 1
	mut f := 0
	mut v := 0
	mut r := 0
	mut b := 0
	mut vic := 0
	for y in 0 .. app.tilenum {
		for x in 0 .. app.tilenum {
			if tiles[x][y] == app.turn {
				f = 0
				v = 0
				r = 0
				b = 0
				//
				o = 1
				for (x - o) >= 0 && (y - o) >= 0 && tiles[x - o][y - o] == app.turn {
					o++
					f++
				}
				o = 1
				for (x + o) <= (app.tilenum - 1) &&
					(y + o) <= (app.tilenum - 1) && tiles[x + o][y + o] == app.turn {
					o++
					f++
				}
				//
				o = 1
				for (x - o) >= 0 && tiles[x - o][y] == app.turn {
					o++
					v++
				}
				o = 1
				for (x + o) <= (app.tilenum - 1) && tiles[x + o][y] == app.turn {
					o++
					v++
				}
				//
				o = 1
				for (x + o) <= (app.tilenum - 1) && (y - o) >= 0 && tiles[x + o][y - o] == app.turn {
					o++
					r++
				}
				o = 1
				for (x - o) >= 0 && (y + o) <= (app.tilenum - 1) && tiles[x - o][y + o] == app.turn {
					o++
					r++
				}
				//
				o = 1
				for (y - o) >= 0 && tiles[x][y - o] == app.turn {
					o++
					b++
				}
				o = 1
				for (y + o) <= (app.tilenum - 1) && tiles[x][y + o] == app.turn {
					o++
					b++
				}
				if f >= 4 || v >= 4 || r >= 4 || b >= 4 {
					vic = 1
				}
			}
		}
	}
	if vic == 0 {
		return 0
	} else {
		return 1
	}
}

fn (mut app App) inv_1(ti [][]int) [][]int {
	mut tiles := ti.clone()
	mut r := 0
	mut o := 0
	mut x := 0
	mut y := 0
	for o != 1 {
		x++
		y++
		if tiles[app.pos_x - x][app.pos_y - y] == app.turn {
			break
		}
		if tiles[app.pos_x - x][app.pos_y - y] == 0 || (app.pos_x - x) <= 0 || (app.pos_y - y) <= 0 {
			o = 1
		}
		if app.sol[app.pos_x - x][app.pos_y - y] == 1 {
			r = 1
		}
	}
	if o == 0 && r == 1 {
		app.not = 1
	}
	if o == 0 {
		for oy in 1 .. y {
			tiles[app.pos_x - oy][app.pos_y - oy] = app.turn
		}
		app.inv = 1
	}
	return tiles
}

fn (mut app App) inv_2(ti [][]int) [][]int {
	mut tiles := ti.clone()
	mut r := 0
	mut o := 0
	mut y := 0
	for o != 1 {
		y++
		if tiles[app.pos_x][app.pos_y - y] == app.turn {
			break
		}
		if tiles[app.pos_x][app.pos_y - y] == 0 || (app.pos_y - y) <= 0 {
			o = 1
		}
		if app.sol[app.pos_x][app.pos_y - y] == 1 {
			r = 1
		}
	}
	if o == 0 && r == 1 {
		app.not = 1
	}
	if o == 0 {
		for oy in 1 .. y {
			tiles[app.pos_x][app.pos_y - oy] = app.turn
		}
		app.inv = 1
	}
	return tiles
}

fn (mut app App) inv_3(ti [][]int) [][]int {
	mut tiles := ti.clone()
	mut r := 0
	mut o := 0
	mut x := 0
	mut y := 0
	for o != 1 {
		x++
		y++
		if tiles[app.pos_x + x][app.pos_y - y] == app.turn {
			break
		}
		if tiles[app.pos_x + x][app.pos_y - y] == 0 ||
			(app.pos_x + x) >= app.tilenum - 1 || (app.pos_y - y) <= 0 {
			o = 1
		}
		if app.sol[app.pos_x + x][app.pos_y - y] == 1 {
			r = 1
		}
	}
	if o == 0 && r == 1 {
		app.not = 1
	}
	if o == 0 {
		for oy in 1 .. y {
			tiles[app.pos_x + oy][app.pos_y - oy] = app.turn
		}
		app.inv = 1
	}
	return tiles
}

fn (mut app App) inv_4(ti [][]int) [][]int {
	mut tiles := ti.clone()
	mut r := 0
	mut o := 0
	mut x := 0
	for o != 1 {
		x++
		if tiles[app.pos_x - x][app.pos_y] == app.turn {
			break
		}
		if tiles[app.pos_x - x][app.pos_y] == 0 || (app.pos_x - x) <= 0 {
			o = 1
		}
		if app.sol[app.pos_x - x][app.pos_y] == 1 {
			r = 1
		}
	}
	if o == 0 && r == 1 {
		app.not = 1
	}
	if o == 0 {
		for oy in 1 .. x {
			tiles[app.pos_x - oy][app.pos_y] = app.turn
		}
		app.inv = 1
	}
	return tiles
}

fn (mut app App) inv_5(ti [][]int) [][]int {
	mut tiles := ti.clone()
	mut r := 0
	mut o := 0
	mut x := 0
	for o != 1 {
		x++
		if tiles[app.pos_x + x][app.pos_y] == app.turn {
			break
		}
		if tiles[app.pos_x + x][app.pos_y] == 0 || (app.pos_x + x) >= app.tilenum - 1 {
			o = 1
		}
		if app.sol[app.pos_x + x][app.pos_y] == 1 {
			r = 1
		}
	}
	if o == 0 && r == 1 {
		app.not = 1
	}
	if o == 0 {
		for oy in 1 .. x {
			tiles[app.pos_x + oy][app.pos_y] = app.turn
		}
		app.inv = 1
	}
	return tiles
}

fn (mut app App) inv_6(ti [][]int) [][]int {
	mut tiles := ti.clone()
	mut r := 0
	mut o := 0
	mut x := 0
	mut y := 0
	for o != 1 {
		x++
		y++
		if tiles[app.pos_x - x][app.pos_y + y] == app.turn {
			break
		}
		if tiles[app.pos_x - x][app.pos_y + y] == 0 ||
			(app.pos_x - x) <= 0 || (app.pos_y + y) >= app.tilenum - 1 {
			o = 1
		}
		if app.sol[app.pos_x - x][app.pos_y + y] == 1 {
			r = 1
		}
	}
	if o == 0 && r == 1 {
		app.not = 1
	}
	if o == 0 {
		for oy in 1 .. y {
			tiles[app.pos_x - oy][app.pos_y + oy] = app.turn
		}
		app.inv = 1
	}
	return tiles
}

fn (mut app App) inv_7(ti [][]int) [][]int {
	mut tiles := ti.clone()
	mut r := 0
	mut o := 0
	mut y := 0
	for o != 1 {
		y++
		if tiles[app.pos_x][app.pos_y + y] == app.turn {
			break
		}
		if tiles[app.pos_x][app.pos_y + y] == 0 || (app.pos_y + y) >= app.tilenum - 1 {
			o = 1
		}
		if app.sol[app.pos_x][app.pos_y + y] == 1 {
			r = 1
		}
	}
	if o == 0 && r == 1 {
		app.not = 1
	}
	if o == 0 {
		for oy in 1 .. y {
			tiles[app.pos_x][app.pos_y + oy] = app.turn
		}
		app.inv = 1
	}
	return tiles
}

fn (mut app App) inv_8(ti [][]int) [][]int {
	mut tiles := ti.clone()
	mut r := 0
	mut o := 0
	mut x := 0
	mut y := 0
	for o != 1 {
		x++
		y++
		if tiles[app.pos_x + x][app.pos_y + y] == app.turn {
			break
		}
		if tiles[app.pos_x + x][app.pos_y + y] == 0 ||
			(app.pos_x + x) >= app.tilenum - 1 || (app.pos_y + y) >= app.tilenum - 1 {
			o = 1
		}
		if app.sol[app.pos_x + x][app.pos_y + y] == 1 {
			r = 1
		}
	}
	if o == 0 && r == 1 {
		app.not = 1
	}
	if o == 0 {
		for oy in 1 .. y {
			tiles[app.pos_x + oy][app.pos_y + oy] = app.turn
		}
		app.inv = 1
	}
	return tiles
}

// put key
fn (mut app App) on_key_down(key sapp.KeyCode) {
	match key {
		.w, .up { app.up() }
		.a, .left { app.left() }
		.s, .down { app.down() }
		.d, .right { app.right() }
		.space, .enter { app.space() }
		else {}
	}
}

fn (mut app App) reset() {
	app.first = 1
	app.turn = 1
	app.vic = 0
	app.inv = 0
	app.not = 0
	app.pos_x = 4
	app.pos_y = 4
	app.tiles = [][]int{len: 9, init: []int{len: 9}}
	app.sol = [][]int{len: 9, init: []int{len: 9}}
}

// processing when event
fn on_event(e &sapp.Event, mut app App) {
	match e.typ {
		.resized, .restored, .resumed {
			app.resize()
		}
		.key_down {
			if app.vic == 0 {
				app.on_key_down(e.key_code)
			} else if e.key_code == .space {
				app.reset()
			}
		}
		else {}
	}
}
