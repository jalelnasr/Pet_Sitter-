package com.petsitter.store.product;

import java.io.IOException;
import java.io.UncheckedIOException;
import java.nio.charset.StandardCharsets;
import java.nio.file.Files;
import java.nio.file.Path;
import java.util.Arrays;
import java.util.UUID;

import org.springframework.beans.factory.annotation.Value;
import org.springframework.stereotype.Service;
import org.springframework.web.multipart.MultipartFile;

import com.petsitter.common.exception.BadRequestException;

/** Photos des produits, rangées dans le dossier d'envoi commun et servies par {@code /uploads/**}. */
@Service
public class ProductImageService {

	private static final long MAX_BYTES = 5 * 1024 * 1024;

	private final Path directory;

	public ProductImageService(@Value("${petsitter.upload.dir:uploads}") String uploadDir) {
		this.directory = Path.of(uploadDir, "products").toAbsolutePath().normalize();
	}

	/** Enregistre une photo et renvoie son adresse publique. */
	public String store(MultipartFile file) {
		byte[] bytes = read(file);
		if (bytes.length == 0) {
			throw new BadRequestException("STORE_IMAGE_EMPTY", "Le fichier est vide.");
		}
		if (bytes.length > MAX_BYTES) {
			throw new BadRequestException("STORE_IMAGE_TOO_LARGE", "La photo dépasse 5 Mo.");
		}
		// Le nom vient du serveur et le type du contenu réel : rien de ce que déclare le client n'est repris.
		String name = UUID.randomUUID() + extensionOf(bytes);
		try {
			Files.createDirectories(directory);
			Files.write(directory.resolve(name), bytes);
		}
		catch (IOException e) {
			throw new UncheckedIOException(e);
		}
		return "/uploads/products/" + name;
	}

	private static byte[] read(MultipartFile file) {
		try {
			return file.getBytes();
		}
		catch (IOException e) {
			throw new UncheckedIOException(e);
		}
	}

	private static String extensionOf(byte[] b) {
		if (startsWith(b, 0xFF, 0xD8, 0xFF)) {
			return ".jpg";
		}
		if (startsWith(b, 0x89, 'P', 'N', 'G', 0x0D, 0x0A, 0x1A, 0x0A)) {
			return ".png";
		}
		if (b.length >= 12 && ascii(b, 0, 4).equals("RIFF") && ascii(b, 8, 12).equals("WEBP")) {
			return ".webp";
		}
		throw new BadRequestException("STORE_IMAGE_TYPE", "Choisissez une image JPG, PNG ou WebP.");
	}

	private static boolean startsWith(byte[] bytes, int... prefix) {
		if (bytes.length < prefix.length) {
			return false;
		}
		for (int i = 0; i < prefix.length; i++) {
			if ((bytes[i] & 0xFF) != prefix[i]) {
				return false;
			}
		}
		return true;
	}

	private static String ascii(byte[] bytes, int from, int to) {
		return new String(Arrays.copyOfRange(bytes, from, to), StandardCharsets.US_ASCII);
	}

}
