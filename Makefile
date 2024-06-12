.SUFFIXES: .scm .exe

run:
	(\
		ol-rl -r server.scm &   \
		ol-rl -r client.scm 8 & \
		ol-rl -r client.scm 3 & \
		wait \
	)
ol-rl.exe:
	curl -O https://pub.krzysckh.org/ol-rl.exe
.scm.exe:
	wine ol-rl.exe -x c $< \
	| i686-w64-mingw32-gcc -o $@ -I/usr/local/include -x c - \
		-L. -l:libraylib5-winlegacy.a -lm -lopengl32 \
		-lwinmm -lgdi32 -lws2_32 -static
pubcpy: client.exe
	yes | pubcpy owl-rgp client.exe
clean:
	rm -f client.exe
