locals {
  ip_octet_braille_characters = split("", join("", [
    base64decode("4qCA4qCB4qCC4qCD4qCE4qCF4qCG4qCH4qCI4qCJ4qCK4qCL4qCM4qCN4qCO4qCP4qCQ4qCR4qCS4qCT"),
    base64decode("4qCU4qCV4qCW4qCX4qCY4qCZ4qCa4qCb4qCc4qCd4qCe4qCf4qCg4qCh4qCi4qCj4qCk4qCl4qCm4qCn"),
    base64decode("4qCo4qCp4qCq4qCr4qCs4qCt4qCu4qCv4qCw4qCx4qCy4qCz4qC04qC14qC24qC34qC44qC54qC64qC7"),
    base64decode("4qC84qC94qC+4qC/4qGA4qGB4qGC4qGD4qGE4qGF4qGG4qGH4qGI4qGJ4qGK4qGL4qGM4qGN4qGO4qGP"),
    base64decode("4qGQ4qGR4qGS4qGT4qGU4qGV4qGW4qGX4qGY4qGZ4qGa4qGb4qGc4qGd4qGe4qGf4qGg4qGh4qGi4qGj"),
    base64decode("4qGk4qGl4qGm4qGn4qGo4qGp4qGq4qGr4qGs4qGt4qGu4qGv4qGw4qGx4qGy4qGz4qG04qG14qG24qG3"),
    base64decode("4qG44qG54qG64qG74qG84qG94qG+4qG/4qKA4qKB4qKC4qKD4qKE4qKF4qKG4qKH4qKI4qKJ4qKK4qKL"),
    base64decode("4qKM4qKN4qKO4qKP4qKQ4qKR4qKS4qKT4qKU4qKV4qKW4qKX4qKY4qKZ4qKa4qKb4qKc4qKd4qKe4qKf"),
    base64decode("4qKg4qKh4qKi4qKj4qKk4qKl4qKm4qKn4qKo4qKp4qKq4qKr4qKs4qKt4qKu4qKv4qKw4qKx4qKy4qKz"),
    base64decode("4qK04qK14qK24qK34qK44qK54qK64qK74qK84qK94qK+4qK/4qOA4qOB4qOC4qOD4qOE4qOF4qOG4qOH"),
    base64decode("4qOI4qOJ4qOK4qOL4qOM4qON4qOO4qOP4qOQ4qOR4qOS4qOT4qOU4qOV4qOW4qOX4qOY4qOZ4qOa4qOb"),
    base64decode("4qOc4qOd4qOe4qOf4qOg4qOh4qOi4qOj4qOk4qOl4qOm4qOn4qOo4qOp4qOq4qOr4qOs4qOt4qOu4qOv4qOw4qOx4qOy4qOz"),
    base64decode("4qO04qO14qO24qO34qO44qO54qO64qO74qO84qO94qO+4qO/")
  ]))

  # Octet bits map bottom-to-top, left-to-right; Braille dots use Unicode's dot positions.
  ip_octet_braille_dot_order = [6, 7, 2, 5, 1, 4, 0, 3]

  ip_octet_braille = {
    for octet in range(256) : octet => local.ip_octet_braille_characters[sum([
      for bit, braille_dot in local.ip_octet_braille_dot_order :
      (floor(octet / pow(2, bit)) % 2) * pow(2, braille_dot)
    ])]
  }
}
