package fr.hasteria.tempsmort.domain

/** Format de jeu : nombre de joueurs sur le terrain. */
enum class GameFormat(val playersOnCourt: Int, val label: String) {
    SIX(6, "6x6"),
    FOUR(4, "4x4"),
    TWO(2, "2x2"),
}

/** Genre de l'équipe. Une équipe mixte impose un minimum de femmes sur le terrain. */
enum class TeamGender(val label: String) {
    FEMININE("Féminine"),
    MASCULINE("Masculine"),
    MIXTE("Mixte"),
}

enum class PlayerGender { F, M }

/**
 * Catégories d'âge, des plus jeunes aux vétérans, plus le loisir.
 * [suggestedFormat] n'est qu'une valeur par défaut à la création d'équipe : le coach choisit librement.
 */
enum class Category(val label: String, val suggestedFormat: GameFormat) {
    M7("M7 · baby-volley", GameFormat.TWO),
    M9("M9", GameFormat.TWO),
    M11("M11", GameFormat.TWO),
    M13("M13", GameFormat.FOUR),
    M15("M15", GameFormat.SIX),
    M18("M18", GameFormat.SIX),
    M21("M21", GameFormat.SIX),
    SENIORS("Seniors", GameFormat.SIX),
    VETERANS("Vétérans", GameFormat.SIX),
    LOISIR("Loisir", GameFormat.SIX),
}

enum class Role { PASSEUR, POINTU, CENTRAL, RECEPTIONNEUR_ATTAQUANT, LIBERO, POLYVALENT }

data class Player(
    val id: String,
    val firstName: String,
    val number: Int,
    val gender: PlayerGender,
    val role: Role = Role.POLYVALENT,
)

data class Team(
    val id: String,
    val name: String,
    val format: GameFormat,
    val gender: TeamGender,
    val category: Category,
    val players: List<Player>,
    /** Pour une équipe mixte : nombre minimum de femmes sur le terrain (souvent la moitié). */
    val minWomenOnCourt: Int = if (gender == TeamGender.MIXTE) format.playersOnCourt / 2 else 0,
) {
    fun player(id: String): Player? = players.firstOrNull { it.id == id }
}
