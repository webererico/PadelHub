enum BadgeType {
  pneuFurado('Pneu Furado', 'Venceu um set por 6/0'),
  nomadeDoPadel('Nômade do Padel', 'Jogou em 5 arenas diferentes'),
  inimigoDoErro('Inimigo do Erro', 'Terminou uma partida oficial com erros mínimos');

  const BadgeType(this.label, this.description);

  final String label;
  final String description;
}

class PlayerBadge {
  const PlayerBadge({required this.type, required this.unlockedAt});

  final BadgeType type;
  final DateTime unlockedAt;
}
