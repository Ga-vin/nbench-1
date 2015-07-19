set APP=../Debug/nbench
set APP_NAME=nbench
set APP_GMON=gmon.out

arm-sylixos-eabi-gprof %APP% %APP_GMON% > %APP_NAME%_gprof.log
gprof2dot.py -e0 -n0 %APP_NAME%_gprof.log > %APP_NAME%_gprof.dot  
dot -Tpng %APP_NAME%_gprof.dot -o %APP_NAME%_gprof.png
dot -Tsvg %APP_NAME%_gprof.dot -o %APP_NAME%_gprof.svg

set APP=../../libgmon/libsylixos/Debug/libvpmpdm.so
set APP_NAME=libvpmpdm
set APP_GMON=libvpmpdm_gmon.out

arm-sylixos-eabi-gprof %APP% %APP_GMON% > %APP_NAME%_gprof.log
gprof2dot.py -e0 -n0 %APP_NAME%_gprof.log > %APP_NAME%_gprof.dot  
dot -Tpng %APP_NAME%_gprof.dot -o %APP_NAME%_gprof.png
dot -Tsvg %APP_NAME%_gprof.dot -o %APP_NAME%_gprof.svg

pause