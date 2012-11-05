
int main() {
	struct pos2 point[2],clipped[2];
	int c,redraw=1;
	int pointsel=0;
	int doclip=1;

	point[0].x = 40;
	point[0].y = 40;
	point[1].x = 120;
	point[1].y = 100;
	setup_graphics();

	do {
		if (redraw) {
			redraw = 0;
			clear_screen();
			if (point[0].x >= 0 && point[0].x < WIDTH && point[0].y >= 0 && point[0].y < HEIGHT)
				plot(point[0].x,point[0].y,0x04);
			if (point[1].x >= 0 && point[1].x < WIDTH && point[1].y >= 0 && point[1].y < HEIGHT)
				plot(point[1].x,point[1].y,0x04);
			if (doclip) {
				if (clip_line(clipped,point)) {
					draw_line(clipped[0].x,clipped[0].y,clipped[1].x,clipped[1].y,0x0F);
				}
			}
			else {
				draw_line(point[0].x,point[0].y,point[1].x,point[1].y,0x0F);
			}
		}

		c = getch();
		if (c == 0) c = getch() << 8;

		if (c == 27) break;
		else if (c == ' ') pointsel ^= 1;
		else if (c == 0x4800) { /* UP */
			point[pointsel].y--;
			redraw = 1;
		}
		else if (c == 0x5000) { /* DOWN */
			point[pointsel].y++;
			redraw = 1;
		}
		else if (c == 0x4B00) { /* LEFT */
			point[pointsel].x--;
			redraw = 1;
		}
		else if (c == 0x4D00) { /* RIGHT */
			point[pointsel].x++;
			redraw = 1;
		}
	} while (1);

	unsetup_graphics();
	return 0;
}
