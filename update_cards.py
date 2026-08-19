with open("public/dashboard.html", "r") as f:
    content = f.read()

# Remplacement des styles de cartes par des couleurs distinctes et vivantes
new_style = """
<style>
  .card-mini { background: linear-gradient(135deg, #ffffff 0%, #f1f5f9 100%) !important; border-top: 4px solid #64748b !important; border-radius: 12px !important; }
  .card-bronze { background: linear-gradient(135deg, #fff7ed 0%, #ffedd5 100%) !important; border-top: 4px solid #f97316 !important; border-radius: 12px !important; }
  .card-argent { background: linear-gradient(135deg, #f0fdf4 0%, #dcfce7 100%) !important; border-top: 4px solid #22c55e !important; border-radius: 12px !important; }
  .card-or { background: linear-gradient(135deg, #fefce8 0%, #fef08a 100%) !important; border-top: 4px solid #eab308 !important; border-radius: 12px !important; }
</style>
</head>
"""

if "</head>" in content:
    content = content.replace("</head>", new_style)
    with open("public/dashboard.html", "w") as f:
        f.write(content)
        print("Mise à jour réussie !")
else:
    print("Balise </head> introuvable")
