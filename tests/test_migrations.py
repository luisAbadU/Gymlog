from alembic import command
from alembic.config import Config
from alembic.script import ScriptDirectory


def test_single_migration_head(alembic_config: Config) -> None:
    """Dos 'heads' son dos ramas de migraciones sin unir: se resuelve antes de mergear."""
    heads = ScriptDirectory.from_config(alembic_config).get_heads()
    assert len(heads) == 1


def test_migrations_downgrade_and_upgrade_cleanly(alembic_config: Config) -> None:
    command.downgrade(alembic_config, "base")
    command.upgrade(alembic_config, "head")
