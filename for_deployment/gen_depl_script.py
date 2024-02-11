
LICENSE = """
/*
-------------------------------------------------------------------------------
MIT License

Copyright (c) 2024 Rui Cavaco

Permission is hereby granted, free of charge, to any person obtaining a copy
of this software and associated documentation files (the "Software"), to deal
in the Software without restriction, including without limitation the rights
to use, copy, modify, merge, publish, distribute, sublicense, and/or sell
copies of the Software, and to permit persons to whom the Software is
furnished to do so, subject to the following conditions:

The above copyright notice and this permission notice shall be included in all
copies or substantial portions of the Software.

THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND, EXPRESS OR
IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF MERCHANTABILITY,
FITNESS FOR A PARTICULAR PURPOSE AND NONINFRINGEMENT. IN NO EVENT SHALL THE
AUTHORS OR COPYRIGHT HOLDERS BE LIABLE FOR ANY CLAIM, DAMAGES OR OTHER
LIABILITY, WHETHER IN AN ACTION OF CONTRACT, TORT OR OTHERWISE, ARISING FROM,
OUT OF OR IN CONNECTION WITH THE SOFTWARE OR THE USE OR OTHER DEALINGS IN THE
SOFTWARE.
-------------------------------------------------------------------------------
*/

-- DEPLOYMENT SCRIPT FOR RISCO v2 POSTGRESQL + POSTGIS COMPONENTS --

"""

INIT = r"""

CREATE SCHEMA risco_v2
    AUTHORIZATION risco_v2;


""" ## risco_v2 role must have been created previously

# USER = """
# CREATE ROLE risco_v2 WITH
#   LOGIN
#   NOSUPERUSER
#   NOINHERIT
#   NOCREATEDB
#   NOCREATEROLE
#   NOREPLICATION;

# COMMENT ON ROLE risco_v2 IS 'Support and admin user for RISCO v2 PG database components';
# """



OUT_PATH = "risco_pg_deployment.sql"

import codecs
from os import scandir
from os.path import basename, splitext
from datetime import datetime

def main(p_out_path, p_lic, init=None, db=None):

	with codecs.open(p_out_path, "w", encoding="utf-8") as outfp:

		if not db is None:
			outfp.write(f"\\connect {db}\n")

		outfp.write(p_lic)
		outfp.write(f"-- Generated on {datetime.now().isoformat()}\n")

		if not init is None:
			outfp.write(init)

		for type_str in ["types", "seqs", "tables"]:

			if type_str == "tables":

				hdr = "TABLES"
				print_type = "Table"

			elif type_str == "seqs":

				hdr = "SEQUENCES"
				print_type = "Sequence"

			elif type_str == "types":

				hdr = "DEFINED TYPES"
				print_type = "Type"


			outfp.write(f"\n\n--------------------------------------------------------------------------------\n")
			outfp.write(f"-- ===== {hdr} =====\n")	
			outfp.write(f"--------------------------------------------------------------------------------\n\n")

			for entry in scandir(f"../{type_str}"): # ATENÇÃO - Específico LINUX
				
				if entry.is_file() and entry.name.lower().endswith(".sql"):

					with codecs.open(entry.path, encoding="utf-8") as infp:

						outfp.write(f"\n\n-- ----- {print_type} {splitext(basename(entry.name))[0]} -----\n")

						wscnt = 0
						for li, ln in enumerate(infp):

							if len(ln.strip()) == 0:

								wscnt += 1
								if wscnt == 1:
									outfp.write("\n")

							else:
								if not ln.startswith("--"):

									if li == 0 and wscnt == 0:
										outfp.write("\n")

									wscnt = 0
									outln = ln.replace("riscov2_dev", "risco_v2")
									outln = outln.replace("sup_ap", "risco_v2")
									outfp.write(outln.rstrip() + "\n")




if __name__ == "__main__":
	main(OUT_PATH, LICENSE, init=INIT, db="gisdata")