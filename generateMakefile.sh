cat  Makefile.template.start > Makefile.new

ls *cpp|sed "s/.cpp$/.o \\\\/g" >> Makefile.new

cat  Makefile.template.end >> Makefile.new
