"""add selected_days to routines

Revision ID: add_selected_days
Revises: 089b217373cf
Create Date: 2026-01-07

"""
from alembic import op
import sqlalchemy as sa


# revision identifiers, used by Alembic.
revision = 'add_selected_days'
down_revision = '089b217373cf'
branch_labels = None
depends_on = None


def upgrade():
    # Add selected_days column to routines table
    op.add_column('routines', sa.Column('selected_days', sa.String(length=100), nullable=True))
    
    # Set default value for existing routines to 'all' (every day)
    op.execute("UPDATE routines SET selected_days = 'all' WHERE selected_days IS NULL")


def downgrade():
    # Remove selected_days column
    op.drop_column('routines', 'selected_days')
