from fastapi import FastAPI, HTTPException, status
from pydantic import BaseModel
import asyncpg
import os
from dotenv import load_dotenv

# Charger les variables d'environnement
load_dotenv()

# Modèle pour la création/mise à jour d'un utilisateur
class UserCreate(BaseModel):
    name: str
    email: str

class UserResponse(BaseModel):
    id: int
    name: str
    email: str



app = FastAPI()

# Connexion à la base de données PostgreSQL
async def get_db_pool():
    return await asyncpg.create_pool(
        user=os.getenv("DB_USER"),
        password=os.getenv("DB_PASSWORD"),
        database=os.getenv("DB_NAME"),
        host=os.getenv("DB_HOST"),
        port=os.getenv("DB_PORT", "5432")
    )

@app.on_event("startup")
async def startup():
    app.state.pool = await get_db_pool()

@app.on_event("shutdown")
async def shutdown():
    await app.state.pool.close()

# Créer un utilisateur
@app.post("/users", response_model=UserResponse, status_code=status.HTTP_201_CREATED)
async def create_user(user: UserCreate):
    async with app.state.pool.acquire() as connection:
        result = await connection.fetchrow(
            "INSERT INTO users(name, email) VALUES($1, $2) RETURNING id, name, email",
            user.name, user.email
        )
        return result

# Récupérer tous les utilisateurs
@app.get("/users", response_model=list[UserResponse])
async def get_users():
    async with app.state.pool.acquire() as connection:
        results = await connection.fetch("SELECT id, name, email FROM users")
        return results

# Récupérer un utilisateur par ID
@app.get("/users/{id}", response_model=UserResponse)
async def get_user(id: int):
    async with app.state.pool.acquire() as connection:
        result = await connection.fetchrow("SELECT id, name, email FROM users WHERE id = $1", id)
        if not result:
            raise HTTPException(status_code=404, detail="User not found")
        return result

# Mettre à jour un utilisateur
@app.put("/users/{id}", response_model=UserResponse)
async def update_user(id: int, user: UserCreate):
    async with app.state.pool.acquire() as connection:
        result = await connection.fetchrow(
            "UPDATE users SET name = $1, email = $2 WHERE id = $3 RETURNING id, name, email",
            user.name, user.email, id
        )
        if not result:
            raise HTTPException(status_code=404, detail="User not found")
        return result

# Supprimer un utilisateur
@app.delete("/users/{id}", status_code=status.HTTP_204_NO_CONTENT)
async def delete_user(id: int):
    async with app.state.pool.acquire() as connection:
        result = await connection.fetchrow("DELETE FROM users WHERE id = $1 RETURNING id", id)
        if not result:
            raise HTTPException(status_code=404, detail="User not found")
        return {"message": "User deleted successfully"}

# Démarrer le serveur
if __name__ == "__main__":
    import uvicorn
    uvicorn.run(app, host="0.0.0.0", port=3000)
